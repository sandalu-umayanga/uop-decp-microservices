import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
import { Construct } from 'constructs';

export const SERVICE_NAMES = [
  'api-gateway',
  'auth-service',
  'user-service',
  'post-service',
  'job-service',
  'event-service',
  'research-service',
  'messaging-service',
  'notification-service',
  'analytics-service',
  'mentorship-service',
];

export class DecpInfraStack extends cdk.Stack {
  // Exported for use by DecpServicesStack
  public readonly vpc: ec2.Vpc;
  public readonly cluster: ecs.Cluster;
  public readonly dnsNamespace: servicediscovery.PrivateDnsNamespace;
  public readonly albListener: elbv2.ApplicationListener;
  public readonly alb: elbv2.ApplicationLoadBalancer;
  public readonly servicesSg: ec2.SecurityGroup;
  public readonly executionRole: iam.Role;
  public readonly logGroup: logs.LogGroup;
  public readonly appSecret: secretsmanager.ISecret;
  public readonly infraHost: string;
  public readonly ecrRepos: Record<string, ecr.Repository>;
  public readonly mediaBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ── Secrets Manager ──────────────────
    this.appSecret = secretsmanager.Secret.fromSecretNameV2(this, 'AppSecret', 'decp/app-secrets');

    // ── VPC ──────────────────────────────
    this.vpc = new ec2.Vpc(this, 'DecpVpc', {
      maxAzs: 2,
      natGateways: 1,
    });

    // ── Security Groups ───────────────────
    const albSg = new ec2.SecurityGroup(this, 'AlbSg', {
      vpc: this.vpc,
      description: 'ALB: allow HTTP from internet',
    });
    albSg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80));

    this.servicesSg = new ec2.SecurityGroup(this, 'ServicesSg', {
      vpc: this.vpc,
      description: 'ECS services: allow from ALB and inter-service',
    });
    this.servicesSg.addIngressRule(albSg, ec2.Port.tcp(8080));
    this.servicesSg.addIngressRule(this.servicesSg, ec2.Port.allTraffic());

    const infraSg = new ec2.SecurityGroup(this, 'InfraSg', {
      vpc: this.vpc,
      description: 'Infra EC2: allow DB ports from ECS services',
    });
    infraSg.addIngressRule(this.servicesSg, ec2.Port.tcp(5432));
    infraSg.addIngressRule(this.servicesSg, ec2.Port.tcp(27017));
    infraSg.addIngressRule(this.servicesSg, ec2.Port.tcp(6379));
    infraSg.addIngressRule(this.servicesSg, ec2.Port.tcp(5672));

    // ── Infra EC2 ─────────────────────────
    const infraRole = new iam.Role(this, 'InfraRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });
    this.appSecret.grantRead(infraRole);

    const infraInstance = new ec2.Instance(this, 'InfraInstance', {
      vpc: this.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      securityGroup: infraSg,
      role: infraRole,
      blockDevices: [{ deviceName: '/dev/xvda', volume: ec2.BlockDeviceVolume.ebs(20) }],
    });

    infraInstance.addUserData(
      '#!/bin/bash',
      'set -e',
      'yum update -y',
      'yum install -y docker aws-cli jq',
      'systemctl start docker',
      'systemctl enable docker',
      'mkdir -p /usr/local/lib/docker/cli-plugins',
      'curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose',
      'chmod +x /usr/local/lib/docker/cli-plugins/docker-compose',
      'mkdir -p /opt/decp',
      'cat > /opt/decp/init-postgres.sql << \'INITSQL\'',
      'CREATE DATABASE decp_user_db;',
      'CREATE DATABASE decp_job_db;',
      'CREATE DATABASE decp_event_db;',
      'CREATE DATABASE decp_research_db;',
      'CREATE DATABASE decp_mentorship_db;',
      'CREATE DATABASE decp_analytics_db;',
      'INITSQL',
      'cat > /opt/decp/docker-compose.yml << \'COMPOSEFILE\'',
      'services:',
      '  postgres:',
      '    image: postgres:15-alpine',
      '    environment:',
      '      POSTGRES_USER: decp_user',
      '      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}',
      '      POSTGRES_DB: decp_db',
      '    ports: ["5432:5432"]',
      '    volumes:',
      '      - postgres_data:/var/lib/postgresql/data',
      '      - /opt/decp/init-postgres.sql:/docker-entrypoint-initdb.d/init-postgres.sql',
      '    restart: unless-stopped',
      '  mongodb:',
      '    image: mongo:6.0',
      '    environment:',
      '      MONGO_INITDB_ROOT_USERNAME: ${MONGO_ROOT_USERNAME}',
      '      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD}',
      '    ports: ["27017:27017"]',
      '    volumes: [mongodb_data:/data/db]',
      '    restart: unless-stopped',
      '  redis:',
      '    image: redis:7-alpine',
      '    ports: ["6379:6379"]',
      '    restart: unless-stopped',
      '  rabbitmq:',
      '    image: rabbitmq:3-alpine',
      '    environment:',
      '      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}',
      '      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}',
      '    ports: ["5672:5672"]',
      '    restart: unless-stopped',
      'volumes:',
      '  postgres_data:',
      '  mongodb_data:',
      'COMPOSEFILE',
      'SECRET=$(aws secretsmanager get-secret-value --secret-id decp/app-secrets --query SecretString --output text)',
      'export POSTGRES_PASSWORD=$(echo $SECRET | jq -r .POSTGRES_PASSWORD)',
      'export MONGO_ROOT_USERNAME=$(echo $SECRET | jq -r .MONGO_ROOT_USERNAME)',
      'export MONGO_ROOT_PASSWORD=$(echo $SECRET | jq -r .MONGO_ROOT_PASSWORD)',
      'export RABBITMQ_USER=$(echo $SECRET | jq -r .RABBITMQ_USER)',
      'export RABBITMQ_PASSWORD=$(echo $SECRET | jq -r .RABBITMQ_PASSWORD)',
      'cd /opt/decp && docker compose up -d',
    );

    this.infraHost = infraInstance.instancePrivateIp;

    // ── Media S3 Bucket ───────────────────
    this.mediaBucket = new s3.Bucket(this, 'MediaBucket', {
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: true,
        ignorePublicAcls: true,
        blockPublicPolicy: false,
        restrictPublicBuckets: false,
      }),
      cors: [{
        allowedMethods: [s3.HttpMethods.GET],
        allowedOrigins: ['*'],
        allowedHeaders: ['*'],
      }],
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    this.mediaBucket.addToResourcePolicy(new iam.PolicyStatement({
      actions: ['s3:GetObject'],
      resources: [this.mediaBucket.arnForObjects('*')],
      principals: [new iam.AnyPrincipal()],
    }));

    // ── ECR Repositories ─────────────────
    this.ecrRepos = {};
    for (const name of SERVICE_NAMES) {
      this.ecrRepos[name] = new ecr.Repository(this, `${name}-repo`, {
        repositoryName: `decp/${name}`,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
        emptyOnDelete: true,
        lifecycleRules: [{ maxImageCount: 5 }],
      });
    }

    // ── ECS Cluster ───────────────────────
    this.cluster = new ecs.Cluster(this, 'DecpCluster', {
      vpc: this.vpc,
      clusterName: 'decp-cluster',
      containerInsightsV2: ecs.ContainerInsights.ENABLED,
    });

    // ── Cloud Map (Service Discovery) ─────
    this.dnsNamespace = new servicediscovery.PrivateDnsNamespace(this, 'DecpNamespace', {
      name: 'decp.local',
      vpc: this.vpc,
    });

    // ── CloudWatch Log Group ──────────────
    this.logGroup = new logs.LogGroup(this, 'DecpLogGroup', {
      logGroupName: '/decp/services',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ── ALB ───────────────────────────────
    this.alb = new elbv2.ApplicationLoadBalancer(this, 'DecpAlb', {
      vpc: this.vpc,
      internetFacing: true,
      securityGroup: albSg,
      loadBalancerName: 'decp-alb',
    });

    this.albListener = this.alb.addListener('HttpListener', {
      port: 80,
      defaultAction: elbv2.ListenerAction.fixedResponse(404, { messageBody: 'Not found' }),
    });

    // ── ECS Task Execution Role ───────────
    this.executionRole = new iam.Role(this, 'EcsExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });
    this.appSecret.grantRead(this.executionRole);

    // ── Outputs ───────────────────────────
    new cdk.CfnOutput(this, 'AlbDnsName', {
      value: `http://${this.alb.loadBalancerDnsName}`,
      description: 'API Gateway URL — use as VITE_API_BASE_URL when building the frontend',
    });

    new cdk.CfnOutput(this, 'EcrRegistry', {
      value: `${this.account}.dkr.ecr.${this.region}.amazonaws.com`,
      description: 'ECR registry — needed for push-images.sh',
    });

    new cdk.CfnOutput(this, 'InfraInstancePrivateIp', {
      value: this.infraHost,
      description: 'Private IP of infra EC2 — update INFRA_HOST in decp/app-secrets after deploy',
    });

    new cdk.CfnOutput(this, 'MediaBucketName', {
      value: this.mediaBucket.bucketName,
      description: 'S3 bucket for post media — set as S3_BUCKET_NAME env var in post-service',
    });
  }
}
