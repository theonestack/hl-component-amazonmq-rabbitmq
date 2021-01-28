CfhighlanderTemplate do
  Name 'amazonmq-rabbitmq'
  Description "amazonmq-rabbitmq - #{component_version}"

  DependsOn 'lib-ec2@0.1.0'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DeploymentMode', 'SINGLE_INSTANCE', allowedValues: ['SINGLE_INSTANCE', 'CLUSTER_MULTI_AZ']
    ComponentParam 'EngineVersion', '3.8.6', allowedValues: ['3.8.6']
    ComponentParam 'HostInstanceType', 'mq.t3.micro', allowedValues: ['mq.t3.micro', 'mq.m5.large', 'mq.m5.xlarge', 'mq.m5.2xlarge', 'mq.m5.4xlarge']
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'
  end

  LambdaFunctions 'ssm_custom_resources'
end
