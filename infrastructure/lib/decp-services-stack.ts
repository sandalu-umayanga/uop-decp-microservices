import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';
import { DecpInfraStack } from './decp-infra-stack';

// ─────────────────────────────────────────
// Service definitions
// ─────────────────────────────────────────

interface ServiceDefinition {
  name: string;
  port: number;
  cpu: number;
  memoryMiB: number;
  isPublic: boolean;
  getEnv: (infraHost: string, corsAllowedOrigin: string) => Record<string, string>;
  getSecrets: (appSecret: secretsmanager.ISecret) => Record<string, ecs.Secret>;
}

const SERVICES: ServiceDefinition[] = [
  {
    name: 'api-gateway',
    port: 8080,
    cpu: 512,
    memoryMiB: 1024,
    isPublic: true,
    getEnv: (_host, cors) => ({
      CORS_ALLOWED_ORIGIN: cors,
      AUTH_SERVICE_URL:         'http://auth-service.decp.local:8081',
      USER_SERVICE_URL:         'http://user-service.decp.local:8082',
      POST_SERVICE_URL:         'http://post-service.decp.local:8083',
      JOB_SERVICE_URL:          'http://job-service.decp.local:8084',
      EVENT_SERVICE_URL:        'http://event-service.decp.local:8085',
      RESEARCH_SERVICE_URL:     'http://research-service.decp.local:8086',
      MESSAGING_SERVICE_URL:    'http://messaging-service.decp.local:8087',
      MESSAGING_SERVICE_WS_URL: 'ws://messaging-service.decp.local:8087',
      NOTIFICATION_SERVICE_URL: 'http://notification-service.decp.local:8088',
      ANALYTICS_SERVICE_URL:    'http://analytics-service.decp.local:8089',
      MENTORSHIP_SERVICE_URL:   'http://mentorship-service.decp.local:8090',
    }),
    getSecrets: (s) => ({
      JWT_SECRET: ecs.Secret.fromSecretsManager(s, 'JWT_SECRET'),
    }),
  },
  {
    name: 'auth-service',
    port: 8081,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: () => ({
      USER_SERVICE_URL: 'http://user-service.decp.local:8082',
    }),
    getSecrets: (s) => ({
      JWT_SECRET: ecs.Secret.fromSecretsManager(s, 'JWT_SECRET'),
    }),
  },
  {
    name: 'user-service',
    port: 8082,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_user_db`,
      RABBITMQ_HOST: h,
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'post-service',
    port: 8083,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({ RABBITMQ_HOST: h }),
    getSecrets: (s) => ({
      SPRING_DATA_MONGODB_URI: ecs.Secret.fromSecretsManager(s, 'MONGODB_URI_POSTS'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'job-service',
    port: 8084,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_job_db`,
      RABBITMQ_HOST: h,
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'event-service',
    port: 8085,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_event_db`,
      RABBITMQ_HOST: h,
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'research-service',
    port: 8086,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_research_db`,
      RABBITMQ_HOST: h,
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'messaging-service',
    port: 8087,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({ REDIS_HOST: h, REDIS_PORT: '6379' }),
    getSecrets: (s) => ({
      SPRING_DATA_MONGODB_URI: ecs.Secret.fromSecretsManager(s, 'MONGODB_URI_MESSAGING'),
    }),
  },
  {
    name: 'notification-service',
    port: 8088,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({ RABBITMQ_HOST: h, REDIS_HOST: h, REDIS_PORT: '6379' }),
    getSecrets: (s) => ({
      SPRING_DATA_MONGODB_URI: ecs.Secret.fromSecretsManager(s, 'MONGODB_URI_NOTIFICATIONS'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'analytics-service',
    port: 8089,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_analytics_db`,
      RABBITMQ_HOST: h,
      REDIS_HOST: h,
      REDIS_PORT: '6379',
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
  {
    name: 'mentorship-service',
    port: 8090,
    cpu: 256,
    memoryMiB: 512,
    isPublic: false,
    getEnv: (h) => ({
      SPRING_DATASOURCE_URL: `jdbc:postgresql://${h}:5432/decp_mentorship_db`,
      RABBITMQ_HOST: h,
      REDIS_HOST: h,
      REDIS_PORT: '6379',
    }),
    getSecrets: (s) => ({
      POSTGRES_USER: ecs.Secret.fromSecretsManager(s, 'POSTGRES_USER'),
      POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(s, 'POSTGRES_PASSWORD'),
      RABBITMQ_USER: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_USER'),
      RABBITMQ_PASSWORD: ecs.Secret.fromSecretsManager(s, 'RABBITMQ_PASSWORD'),
    }),
  },
];

// ─────────────────────────────────────────
// Stack
// ─────────────────────────────────────────

interface DecpServicesStackProps extends cdk.StackProps {
  infra: DecpInfraStack;
  corsAllowedOrigin: string;
}

export class DecpServicesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: DecpServicesStackProps) {
    super(scope, id, props);

    const { infra, corsAllowedOrigin } = props;

    for (const svc of SERVICES) {
      // post-service gets a dedicated task role with S3 write permission
      let taskRole: iam.Role | undefined;
      if (svc.name === 'post-service') {
        taskRole = new iam.Role(this, 'PostServiceTaskRole', {
          assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
        });
        infra.mediaBucket.grantWrite(taskRole);
      }

      const taskDef = new ecs.FargateTaskDefinition(this, `${svc.name}-task`, {
        cpu: svc.cpu,
        memoryLimitMiB: svc.memoryMiB,
        executionRole: infra.executionRole,
        ...(taskRole ? { taskRole } : {}),
      });

      const extraEnv: Record<string, string> = svc.name === 'post-service'
        ? { S3_BUCKET_NAME: infra.mediaBucket.bucketName }
        : {};

      taskDef.addContainer(`${svc.name}-container`, {
        image: ecs.ContainerImage.fromEcrRepository(infra.ecrRepos[svc.name], 'latest'),
        portMappings: [{ containerPort: svc.port }],
        environment: { ...svc.getEnv(infra.infraHost, corsAllowedOrigin), ...extraEnv },
        secrets: svc.getSecrets(infra.appSecret),
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: svc.name,
          logGroup: infra.logGroup,
        }),
      });

      const ecsService = new ecs.FargateService(this, `${svc.name}-service`, {
        cluster: infra.cluster,
        taskDefinition: taskDef,
        desiredCount: 1,
        securityGroups: [infra.servicesSg],
        vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
        serviceName: svc.name,
        assignPublicIp: false,
        minHealthyPercent: 100,
        maxHealthyPercent: 200,
        circuitBreaker: { enable: false, rollback: false },
        healthCheckGracePeriod: cdk.Duration.seconds(60),
        cloudMapOptions: {
          name: svc.name,
          cloudMapNamespace: infra.dnsNamespace,
        },
      });

      if (svc.isPublic) {
        const targetGroup = new elbv2.ApplicationTargetGroup(this, `${svc.name}-tg`, {
          vpc: infra.vpc,
          port: svc.port,
          protocol: elbv2.ApplicationProtocol.HTTP,
          targets: [ecsService],
          deregistrationDelay: cdk.Duration.seconds(30),
          healthCheck: {
            path: '/actuator/health',
            interval: cdk.Duration.seconds(30),
            timeout: cdk.Duration.seconds(10),
            healthyThresholdCount: 2,
            unhealthyThresholdCount: 5,
          },
        });

        // Use ApplicationListenerRule (not listener.addTargetGroups) so the
        // rule resource is owned by ServicesStack, avoiding a cyclic reference.
        new elbv2.ApplicationListenerRule(this, `${svc.name}-rule`, {
          listener: infra.albListener,
          priority: 10,
          conditions: [elbv2.ListenerCondition.pathPatterns(['/*'])],
          action: elbv2.ListenerAction.forward([targetGroup]),
        });
      }
    }
  }
}
