CloudFormation do

  Condition(:SingleInstance, FnEquals(Ref('DeploymentMode'), 'SINGLE_INSTANCE'))

  export_name = external_parameters.fetch(:export_name, component_name)
  tags = []
  tags << { Key: 'Environment', Value: Ref('EnvironmentName') }
  tags << { Key: 'EnvironmentType', Value: Ref('EnvironmentType') }
  extra_tags = external_parameters.fetch(:extra_tags, {})
  extra_tags.each { |key,value| tags << { Key: FnSub(key), Value: FnSub(value) } }


  ip_blocks = external_parameters.fetch(:ip_blocks, {})
  security_group_rules = external_parameters.fetch(:security_group_rules, [])

  EC2_SecurityGroup(:SecurityGroup) {
    VpcId Ref(:VPCId)
    GroupDescription FnSub("${EnvironmentName}-#{export_name}")
    if security_group_rules.any?
      SecurityGroupIngress generate_security_group_rules(security_group_rules,ip_blocks)
    end
    Tags tags
  }

  username = external_parameters.fetch(:username, 'administrator')
  Resource("PasswordSSMSecureParameter") {
    Type "Custom::SSMSecureParameter"
    Property('ServiceToken', FnGetAtt('SSMSecureParameterCR', 'Arn'))
    Property('Path', FnSub("/#{export_name}/${EnvironmentName}/password"))
    Property('Description', FnSub("${EnvironmentName} RabbitMQ User #{username} Password"))
    Property('Tags',[
      { Key: 'Name', Value: FnSub("${EnvironmentName}-#{username}-rabbitmq-password")},
      { Key: 'Environment', Value: FnSub("${EnvironmentName}")},
      { Key: 'EnvironmentType', Value: FnSub("${EnvironmentType}")}
    ])
  }

  SSM_Parameter("UsernameParameterSecretKey") {
    Name FnSub("/#{export_name}/${EnvironmentName}/username")
    Type 'String'
    Value "#{username}"
  }

  # Only one set of creds can be created at launch when using rabbit
  broker_credentials = {
    Username: username,
    Password: FnGetAtt('PasswordSSMSecureParameter', 'Password')
  }

  broker_users = []
  broker_users << broker_credentials
  additional_users = external_parameters.fetch(:additional_users, [])
  additional_users.each_with_index do |user,i|
    case user['type']
    when "static"
      username = user['username']
      password = user['password']
      broker_users << {
        Username: username,
        Password: password
      }
    when "ssm"
      username = FnSub("{{resolve:ssm:#{user['username']}}}")
      password = FnSub("{{resolve:ssm:#{user['password']}}}")
      broker_users << {
        Username: username,
        Password: password
      }
    when "ssm-generate"
      username = user['username']
      SSM_Parameter("UsernameParameter#{i+1}") {
        Name FnSub("#{user['ssmusername']}")
        Type 'String'
        Value "#{username}"
      }
      Resource("PasswordParameter#{i+1}") {
        Type "Custom::SSMSecureParameter"
        Property('ServiceToken', FnGetAtt('SSMSecureParameterCR', 'Arn'))
        Property('Path', FnSub("#{user['ssmpassword']}"))
        Property('Description', FnSub("${EnvironmentName} RabbitMQ User #{username} Password"))
        Property('Tags',[
          { Key: 'Name', Value: FnSub("${EnvironmentName}-#{username}-rabbitmq-password")},
          { Key: 'Environment', Value: FnSub("${EnvironmentName}")},
          { Key: 'EnvironmentType', Value: FnSub("${EnvironmentType}")}
        ])
      }
      password = FnGetAtt("PasswordParameter#{i+1}", 'Password')
      broker_users << {
        Username: username,
        Password: password
      }
    end

  end

  auto_minor_upgrade = external_parameters.fetch(:auto_minor_upgrade, false)
  enable_logs = external_parameters.fetch(:enable_logs, true)
  public_access = external_parameters.fetch(:public_access, false)
  maintenance_window = external_parameters.fetch(:maintenance_window, nil)
  storage_type = external_parameters.fetch(:storage_type, nil)
  AmazonMQ_Broker(:Broker) {
    AutoMinorVersionUpgrade auto_minor_upgrade
    BrokerName FnSub("${EnvironmentName}-#{export_name}")
    DeploymentMode Ref(:DeploymentMode)
    EngineType "RABBITMQ"
    EngineVersion Ref(:EngineVersion)
    HostInstanceType Ref(:HostInstanceType)
    Logs enable_logs ? ({ General: true}) : ({ General: false})
    MaintenanceWindowStartTime maintenance_window unless maintenance_window.nil?
    PubliclyAccessible public_access
    SecurityGroups [Ref(:SecurityGroup)]
    StorageType storage_type unless storage_type.nil?
    SubnetIds FnIf(:SingleInstance, [FnSelect(0, Ref(:SubnetIds))], Ref(:SubnetIds))
    Tags tags
    Users broker_users
  }

  Output(:SecurityGroup) {
    Value(Ref(:SecurityGroup))
    Export FnSub("${EnvironmentName}-#{export_name}-SecurityGroup")
  }

  Output(:BrokerArn) {
    Value(FnGetAtt(:Broker, :Arn))
    Export FnSub("${EnvironmentName}-#{export_name}-Arn")
  }

  Output(:AmqpEndpoints) {
    Value(FnJoin(',', FnGetAtt(:Broker, :AmqpEndpoints)))
    Export FnSub("${EnvironmentName}-#{export_name}-AmqpEndpoints")
  }


end
