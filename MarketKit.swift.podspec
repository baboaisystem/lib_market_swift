Pod::Spec.new do |s|
  s.name             = 'MarketKit.swift'
  s.module_name      = 'MarketKit'
  s.version          = '0.1.0'
  s.summary          = 'Kit provides latest rates for coins, chart data and historical data for different coins and currencies.'

  s.homepage         = 'https://github.com/baboaisystem/lib_market_swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Baboai Systems' => 'snow@baboai.com' }
  s.source           = { git: 'https://github.com/baboaisystem/lib_market_swift.git', tag: "#{s.version}" }
  s.social_media_url = 'https://baboai.com/'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5'

  s.source_files = 'MarketKit/Classes/**/*'
  s.resource_bundle = { 'MarketKit' => 'MarketKit/Resources/*.json' }

  s.requires_arc = true

  s.dependency 'HsToolKit.swift', '~> 1.1'

  s.dependency 'RxSwift', '~> 5.0'
  s.dependency 'RxRelay', '~> 5.0'
  s.dependency 'GRDB.swift', '~> 5.0'
  s.dependency 'ObjectMapper', '~> 4.0'
end
