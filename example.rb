require 'yaml'
require 'pp'
require 'Amiral'
env = YAML.load_file(ARGV[0])
deploy_directive = YAML.load_file(ARGV[1])

am = Amiral.new(env, deploy_directive)
order = am.deploy_order_for_all

pp order

