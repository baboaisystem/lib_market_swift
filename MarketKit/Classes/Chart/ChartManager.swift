import RxSwift

protocol IChartInfoManagerDelegate: AnyObject {
    func didUpdate(chartInfo: ChartInfo, key: ChartInfoKey)
    func didFoundNoChartInfo(key: ChartInfoKey)
}

class ChartManager {
    weak var delegate: IChartInfoManagerDelegate?

    private let coinManager: CoinManager
    private let storage: ChartStorage
    private let provider: CoinGeckoProvider

    init(coinManager: CoinManager, storage: ChartStorage, provider: CoinGeckoProvider) {
        self.coinManager = coinManager
        self.storage = storage
        self.provider = provider
    }

    private static var utcStartOfToday: Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar.startOfDay(for: Date())
    }

    private static func chartInfo(chartPoints: [ChartPoint], key: ChartInfoKey) -> ChartInfo? {
        guard let lastPoint = chartPoints.last else {
            return nil
        }

        let startTimestamp: TimeInterval
        var endTimestamp = Date().timeIntervalSince1970
        let lastPointDiffInterval = endTimestamp - lastPoint.timestamp

        if key.chartType == .today {
            startTimestamp = utcStartOfToday.timeIntervalSince1970
            let day = 24 * 60 * 60
            endTimestamp = startTimestamp + TimeInterval(day)
        } else {
            startTimestamp = lastPoint.timestamp - key.chartType.rangeInterval
        }

        guard lastPointDiffInterval < key.chartType.rangeInterval else {
            return nil
        }

        guard lastPointDiffInterval < key.chartType.expirationInterval else {
            // expired chart info, current timestamp more than last point
            return ChartInfo(
                    points: chartPoints,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    expired: true
            )
        }

        return ChartInfo(
                points: chartPoints,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                expired: false
        )
    }

    private func storedChartPoints(key: ChartInfoKey) -> [ChartPoint] {
        storage.chartPoints(key: key)
    }

}

extension ChartManager {

    func lastSyncTimestamp(key: ChartInfoKey) -> TimeInterval? {
        storedChartPoints(key: key).last?.timestamp
    }

    func chartInfo(coinUid: String, currencyCode: String, chartType: ChartType) -> ChartInfo? {
        guard let fullCoin = try? coinManager.fullCoins(coinUids: [coinUid]).first else {
            return nil
        }

        let key = ChartInfoKey(coin: fullCoin.coin, currencyCode: currencyCode, chartType: chartType)
        return Self.chartInfo(chartPoints: storedChartPoints(key: key), key: key)
    }

    func chartInfoSingle(coinUid: String, currencyCode: String, chartType: ChartType) -> Single<ChartInfo> {
        guard let fullCoin = try? coinManager.fullCoins(coinUids: [coinUid]).first else {
            return Single.error(Kit.KitError.noChartData)
        }

        let key = ChartInfoKey(coin: fullCoin.coin, currencyCode: currencyCode, chartType: chartType)
        return provider
                .chartPointsSingle(key: key)
                .flatMap { points in
                    if let chartInfo = Self.chartInfo(chartPoints: points, key: key) {
                        return Single.just(chartInfo)
                    }
                    return Single.error(Kit.KitError.noChartData)
                }
    }

    func handleUpdated(chartPoints: [ChartPoint], key: ChartInfoKey) {
        let records = chartPoints.map {
            ChartPointRecord(coinUid: key.coin.uid,
                    currencyCode: key.currencyCode,
                    chartType: key.chartType,
                    timestamp: $0.timestamp,
                    value: $0.value,
                    volume: $0.extra[ChartPoint.volume])
        }

        storage.deleteChartPoints(key: key)
        storage.save(chartPoints: records)

        if let chartInfo = Self.chartInfo(chartPoints: chartPoints, key: key) {
            delegate?.didUpdate(chartInfo: chartInfo, key: key)
        } else {
            delegate?.didFoundNoChartInfo(key: key)
        }
    }

    func handleNoChartPoints(key: ChartInfoKey) {
        delegate?.didFoundNoChartInfo(key: key)
    }

}
