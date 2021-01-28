# amazonmq-rabbitmq CfHighlander component

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | String
| EnvironmentType | Tagging | development | true | String | ['development','production']
| VPCId | ID of the VPC to launch in |  | false | AWS::EC2::VPC::Id
| HostInstanceType | The compute and memory capacity of the nodes in the node group (shard) | mq.t3.micro | false | String | ['mq.t3.micro', 'mq.m5.large', 'mq.m5.xlarge', 'mq.m5.2xlarge', 'mq.m5.4xlarge']
| SubnetIds | list of subnet ciders for the broker |  | false | CommaDelimitedList
| DeploymentMode | The type of broker to create | SINGLE_INSTANCE | false | String | [SINGLE_INSTANCE', 'CLUSTER_MULTI_AZ]
| EngineVersion | Engine version for broker | 3.8.6 | false | String | 3.8.6

