import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

// ─────────────────────────────────────────
// Service definitions
// ─────────────────────────────────────────

interface ServiceDefinition {
  name: string;
  port: number;
  cpu: number;
  memoryMiB: number;
  isPublic: boolean; // only api-gateway faces the ALB
  getEnv: (ctx: EnvContext) => Record<string, string>;
  getSecrets: (ctx: SecretsContext) => Record<string, ecs.Secret>;
}

interface EnvContext {
  infraHost: string;
  corsAllowedOrigin: string;
}

interface SecretsContext {
  appSecret: secretsmanager.ISecret;
}

const SERVICES: ServiceDefinition[] = [
  {
    name: 'api-gateway',
    port: 8080,
    cpu: 512,
    memoryMiB: 1024,
    isPublic: true,
    getEnv: ({ corsAllowedOrigin }) => ({
      CORS_ALLOWED_ORIGIN: corsAllowedOrigin,
    }),
    getSecrets: ({ appSecret }) => ({
      JWT_SECRET: ecs.Secret.fromSecretsManager(appSecret, 'JWT_SECRET'),
    }),
  },
  {
    name: 'auth-service',
    port: 8081,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: () => ({}),
    getSecrets: ({ appSecret }) => ({
      JWT_SECRET: ecs.Secret.fromSecretsManager(appSecret, 'JWT_SECRET'),
    }),
  },
  {
    name: 'user-service',
    port: 8082,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_user_db`,
      RABBITMQ_HOST: infraHost,
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'post-service',
    port: 8083,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      RABBITMQ_HOST: infraHost,
    }),
    getSecrets: ({ appSecret }) => ({
      SPRING_DATA_MONGODB_URI: ecs.Secret.fromSecretsManager(appSecret, 'MONGODB_URI_POSTS'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'job-service',
    port: 8084,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_job_db`,
      RABBITMQ_HOST: infraHost,
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'event-service',
    port: 8085,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_event_db`,
      RABBITMQ_HOST: infraHost,
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'research-service',
    port: 8086,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_research_db`,
      RABBITMQ_HOST: infraHost,
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'messaging-service',
    port: 8087,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      REDIS_HOST: infraHost,
      REDIS_PORT: '6379',
    }),
    getSecrets: ({ appSecret }) => ({
      SPRING_DATA_MONGODB_URI_MESSAGING: ecs.Secret.fromSecretsManager(appSecret, 'MONGODB_URI_MESSAGING'),
    }),
  },
  {
    name: 'notification-service',
    port: 8088,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      RABBITMQ_HOST: infraHost,
      REDIS_HOST: infraHost,
      REDIS_PORT: '6379',
    }),
    getSecrets: ({ appSecret }) => ({
      SPRING_DATA_MONGODB_URI_NOTIFICATION: ecs.Secret.fromSecretsManager(appSecret, 'MONGODB_URI_NOTIFICATIONS'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'analytics-service',
    port: 8089,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_analytics_db`,
      RABBITMQ_HOST: infraHost,
      REDIS_HOST: infraHost,
      REDIS_PORT: '6379',
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'mentorship-service',
    port: 8090,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: ({ infraHost }) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${infraHost}:5432/decp_mentorship_db`,
      RABBITMQ_HOST: infraHost,
      REDIS_HOST: infraHost,
      REDIS_PORT: '6379',
    }),
    getSecrets: ({ appSecret }) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(appSecret, 'RABBITMQ_PASSWORD'),
    }),
  },
];

// ─────────────────────────────────────────
// Stack
// ─────────────────────────────────────────

export class DecpStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Read S3 frontend URL from context: cdk deploy -c corsOrigin=http://...
    const corsAllowedOrigin = this.node.tryGetContext('corsOrigin') ?? 'http://localhost:3000';

    // ── Secrets Manager ──────────────────
    // Create the secret once with: aws secretsmanager create-secret --name decp/app-secrets --secret-string '{...}'
    // See scripts/create-secrets.sh for the full command
    const appSecret = secretsmanager.Secret.fromSecretNameV2(this, 'AppSecret', 'decp/app-secrets');

    // ── VPC ──────────────────────────────
    const vpc = new ec2.Vpc(this, 'DecpVpc', {
      maxAzs: 2,
      natGateways: 1, // 1 NAT gateway saves ~$32/mo vs 2
    });

    // ── Security Groups ───────────────────
    const albSg = new ec2.SecurityGroup(this, 'AlbSg', {
      vpc,
      description: 'ALB: allow HTTP from internet',
    });
    albSg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80));

    const servicesSg = new ec2.SecurityGroup(this, 'ServicesSg', {
      vpc,
      description: 'ECS services: allow from ALB and inter-service',
    });
    // ALB can reach api-gateway
    servicesSg.addIngressRule(albSg, ec2.Port.tcp(8080));
    // Services can reach each other
    servicesSg.addIngressRule(servicesSg, ec2.Port.allTraffic());

    const infraSg = new ec2.SecurityGroup(this, 'InfraSg', {
      vpc,
      description: 'Infra EC2: allow DB ports from ECS services',
    });
    infraSg.addIngressRule(servicesSg, ec2.Port.tcp(5432));   // PostgreSQL
    infraSg.addIngressRule(servicesSg, ec2.Port.tcp(27017));  // MongoDB
    infraSg.addIngressRule(servicesSg, ec2.Port.tcp(6379));   // Redis
    infraSg.addIngressRule(servicesSg, ec2.Port.tcp(5672));   // RabbitMQ

    // ── Infra EC2 (PostgreSQL, MongoDB, Redis, RabbitMQ) ──
    const infraRole = new iam.Role(this, 'InfraRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });

    const infraInstance = new ec2.Instance(this, 'InfraInstance', {
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      securityGroup: infraSg,
      role: infraRole,
      blockDevices: [{
        deviceName: '/dev/xvda',
        volume: ec2.BlockDeviceVolume.ebs(20),
      }],
    });

    infraInstance.addUserData(
      '#!/bin/bash',
      'set -e',
      'yum update -y',
      'yum install -y docker',
      'systemctl start docker',
      'systemctl enable docker',
      // Install docker compose plugin
      'mkdir -p /usr/local/lib/docker/cli-plugins',
      'curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose',
      'chmod +x /usr/local/lib/docker/cli-plugins/docker-compose',
      // Write init SQL
      'mkdir -p /opt/decp',
      'cat > /opt/decp/init-postgres.sql << \'INITSQL\'',
      'CREATE DATABASE decp_user_db;',
      'CREATE DATABASE decp_job_db;',
      'CREATE DATABASE decp_event_db;',
      'CREATE DATABASE decp_research_db;',
      'CREATE DATABASE decp_mentorship_db;',
      'CREATE DATABASE decp_analytics_db;',
      'INITSQL',
      // Write docker-compose for infra only
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
      // Fetch secrets from Secrets Manager and start infra
      'yum install -y aws-cli jq',
      'SECRET=$(aws secretsmanager get-secret-value --secret-id decp/app-secrets --query SecretString --output text)',
      'export POSTGRES_PASSWORD=$(echo $SECRET | jq -r .POSTGRES_PASSWORD)',
      'export MONGO_ROOT_USERNAME=$(echo $SECRET | jq -r .MONGO_ROOT_USERNAME)',
      'export MONGO_ROOT_PASSWORD=$(echo $SECRET | jq -r .MONGO_ROOT_PASSWORD)',
      'export RABBITMQ_USER=$(echo $SECRET | jq -r .RABBITMQ_USER)',
      'export RABBITMQ_PASSWORD=$(echo $SECRET | jq -r .RABBITMQ_PASSWORD)',
      'cd /opt/decp && docker compose up -d',
    );

    // Grant infra EC2 access to read the secret
    appSecret.grantRead(infraRole);

    // ── ECR Repositories ─────────────────
    const ecrRepos: Record<string, ecr.Repository> = {};
    for (const svc of SERVICES) {
      ecrRepos[svc.name] = new ecr.Repository(this, `${svc.name}-repo`, {
        repositoryName: `decp/${svc.name}`,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
        emptyOnDelete: true,
        lifecycleRules: [{
          maxImageCount: 5, // keep only last 5 images to save storage costs
        }],
      });
    }

    // ── ECS Cluster ───────────────────────
    const cluster = new ecs.Cluster(this, 'DecpCluster', {
      vpc,
      clusterName: 'decp-cluster',
      containerInsightsV2: ecs.ContainerInsights.ENABLED,
    });

    // ── CloudWatch Log Group ──────────────
    const logGroup = new logs.LogGroup(this, 'DecpLogGroup', {
      logGroupName: '/decp/services',
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // ── ALB ───────────────────────────────
    const alb = new elbv2.ApplicationLoadBalancer(this, 'DecpAlb', {
      vpc,
      internetFacing: true,
      securityGroup: albSg,
      loadBalancerName: 'decp-alb',
    });

    const listener = alb.addListener('HttpListener', {
      port: 80,
      defaultAction: elbv2.ListenerAction.fixedResponse(404, {
        messageBody: 'Not found',
      }),
    });

    // ── Task execution role ───────────────
    const executionRole = new iam.Role(this, 'EcsExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });
    appSecret.grantRead(executionRole);

    // ── ECS Services ──────────────────────
    const envCtx: EnvContext = {
      infraHost: infraInstance.instancePrivateIp,
      corsAllowedOrigin,
    };
    const secretsCtx: SecretsContext = { appSecret };

    for (const svc of SERVICES) {
      const taskDef = new ecs.FargateTaskDefinition(this, `${svc.name}-task`, {
        cpu: svc.cpu,
        memoryLimitMiB: svc.memoryMiB,
        executionRole,
      });

      taskDef.addContainer(`${svc.name}-container`, {
        image: ecs.ContainerImage.fromEcrRepository(ecrRepos[svc.name], 'latest'),
        portMappings: [{ containerPort: svc.port }],
        environment: svc.getEnv(envCtx),
        secrets: svc.getSecrets(secretsCtx),
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: svc.name,
          logGroup,
        }),
      });

      const ecsService = new ecs.FargateService(this, `${svc.name}-service`, {
        cluster,
        taskDefinition: taskDef,
        desiredCount: 1,
        securityGroups: [servicesSg],
        vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
        serviceName: svc.name,
        assignPublicIp: false,
        minHealthyPercent: 0,
        maxHealthyPercent: 100,
      });

      // Only api-gateway gets an ALB target group
      if (svc.isPublic) {
        const targetGroup = new elbv2.ApplicationTargetGroup(this, `${svc.name}-tg`, {
          vpc,
          port: svc.port,
          protocol: elbv2.ApplicationProtocol.HTTP,
          targets: [ecsService],
          healthCheck: {
            path: '/actuator/health',
            interval: cdk.Duration.seconds(30),
            timeout: cdk.Duration.seconds(10),
            healthyThresholdCount: 2,
            unhealthyThresholdCount: 5,
          },
        });

        listener.addTargetGroups(`${svc.name}-rule`, {
          targetGroups: [targetGroup],
          priority: 10,
          conditions: [elbv2.ListenerCondition.pathPatterns(['/*'])],
        });
      }
    }

    // ── Outputs ───────────────────────────
    new cdk.CfnOutput(this, 'AlbDnsName', {
      value: `http://${alb.loadBalancerDnsName}`,
      description: 'API Gateway URL — use this as VITE_API_BASE_URL when building the frontend',
    });

    new cdk.CfnOutput(this, 'EcrRegistry', {
      value: `${this.account}.dkr.ecr.${this.region}.amazonaws.com`,
      description: 'ECR registry — needed for push-images.sh',
    });
  }
}
