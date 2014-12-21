require 'yaml'
require 'pp'
require_relative './lib/amiral'

env = YAML.load_file(ARGV[0])
deploy_directive = YAML.load_file(ARGV[1])
def get_node_for_role env, roles
  env_result = {}
  roles.each { |role|
    env.each { |hostname, content|
      if !content[:roles].nil? and content[:roles].include? role[0] then
        env_result[hostname]= content
      end
    }
  }
  return env_result
end

def clean_from_hostnames env, env_selected
  _env = env
  env_selected.each { |host|
    _env.delete(host)
  }
  return _env
end

deploy_directive_unified = {}

deploy_directive.each{ |group, roles|
  deploy_directive_unified.merge!(roles)
}

deploy_directive.each { |group, roles|
  pp "Deploy the #{group}"
  env_to_deploy = get_node_for_role(env, roles)
  env = clean_from_hostnames(env, env_to_deploy)
  am = Amiral.new(env_to_deploy, deploy_directive_unified)
  deployement_host_step = am.amiral_deploy_order
  pp deployement_host_step
  pp "======="
  pp " "
}

