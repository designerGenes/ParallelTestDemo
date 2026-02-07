Pod::Spec.new do |s|
  s.name         = 'GreetingKit'
  s.version      = '0.1.0'
  s.summary      = 'A trivial local pod for demo purposes.'
  s.description  = 'Provides greeting utilities for the Playground demo app.'
  s.homepage     = 'https://github.com/jadennation/ParallelTestDemo'
  s.license      = { :type => 'MIT', :text => 'MIT License' }
  s.author       = { 'Jaden' => 'jaden@designergen.es' }
  s.source       = { :git => '', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*.{swift}'
end
