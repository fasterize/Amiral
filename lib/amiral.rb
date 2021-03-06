class Amiral
  @env = {}

  @env_global = {}
  @deploy_directive_unified = {}
  @deploy_directive = {}
  @deployement_step = {}


  def initialize env, deploy_directive
    @env_global = env
    @deploy_directive = deploy_directive
    @deploy_directive_unified = {}
    deploy_directive.each{ |group, roles|
      @deploy_directive_unified.merge!(roles)
    }
  end

  def get_ships_for_specific_roles roles
    env_result = {}
    roles.each { |role|
      @env_global.each { |hostname, content|
        if !content[:roles].nil? and content[:roles].include? role[0] then
          env_result[hostname]= content
        end
      }
    }
    return env_result
  end

  def clean_from_from_deployed_ship env, env_selected
    _env = env
    env_selected.each { |host, content|
      _env.delete(host)
    }
    return _env
  end

  def compute_roles
    list_role = {}
    fleet_roles = {}
    @env.each { |name, node|
      list_role = node[:roles] ? node[:roles]: []
      list_role.each { |role|
        fleet_roles[role] = fleet_roles[role].nil? ? 1 : fleet_roles[role].to_i + 1
      }
    }
    return fleet_roles
  end

  # AMIRAL FLEET CONTROL
  def compute_role_deployement_step
    deployement_step = []
    fleet_roles = compute_roles

    fleet_roles.each { |role, number|
      ratio = @deploy_directive_unified[role]["deploy_ratio"].gsub('%','').to_i
      solder_to_deploy = (number * ratio / 100).to_i
      solder_to_deploy = solder_to_deploy == 0 ? 1 : solder_to_deploy
      #pp "solder #{role}: #{solder_to_deploy}/#{number} "
      i = 0
      while fleet_roles[role] > 0 do
        deployement_step[i] = deployement_step[i].nil? ? {} : deployement_step[i]

        if fleet_roles[role] >= solder_to_deploy then
          fleet_roles[role] = fleet_roles[role] - solder_to_deploy
          deployement_step[i][role] = solder_to_deploy
        else
          deployement_step[i][role] = fleet_roles[role]
          fleet_roles[role] = 0
        end
        i = i+1
      end
    }
    return deployement_step
  end

  # AMIRAL: ALL solders .... you are afected to your war boat
  #
  def deploy_order_by_group
    step =0
    deployement_step = compute_role_deployement_step
    deployement_host_step = []
    while @env.length >0 do
      deployement_host_step[step]=[]
      deployement_host_step[step+1]=[]
      nb_machine_before = @env.length
      #pp " @env length before #{@env.length}"

      @env.each { |name, node|
        list_role = node[:roles] ? node[:roles]: []

        if list_role.length == 0 then
          @env.delete(name)
          next
        end

        nb_role_choosen = 0

        list_role.each { |role|
          # pick the role
          if !deployement_step[step][role].nil? and deployement_step[step][role] > 0 then
            nb_role_choosen = nb_role_choosen + 1
          else
            break
          end
        }

        if nb_role_choosen == list_role.length and list_role.length !=0 then
          # all roles statified, add machine to the step et delete her from the list_role
          deployement_host_step[step].push(name)
          @env.delete(name)
          #pp "DELETE HOST #{name}"
          # solder deployed
          list_role.each { |role|
            deployement_step[step][role] = deployement_step[step][role] - 1
          }
        end
      }
      # verify if roles remains , if it's true, add them to the next step
      deployement_step[step].each { |role, number|
        if number > 0 then
          if deployement_step[step+1].nil? then
            deployement_step[step+1] = {}
          end
          deployement_step[step+1][role] = deployement_step[step+1][role].nil? ? number : deployement_step[step+1][role] + number
        end
      }
      #pp " @env length after #{@env.length}"
      nb_machine_after = @env.length
      step = step + 1
      if nb_machine_before == nb_machine_after then
        break
      end
    end
    return deployement_host_step
  end

  def deploy_order_for_all
    deployement_host_step = {}
    @deploy_directive.each { |group, roles|
      @env = get_ships_for_specific_roles roles
      @env_global = clean_from_from_deployed_ship(@env_global, @env)
      deployement_host_step[group] = deploy_order_by_group.delete_if{ |list| list.length == 0 }
    }
    return deployement_host_step
  end

end
