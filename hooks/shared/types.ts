// Lifecycle hook contract, from the ECS developer guide ("Lambda hooks for Amazon ECS service deployments").

export type LifecycleStage =
  | "RECONCILE_SERVICE"
  | "PRE_SCALE_UP"
  | "POST_SCALE_UP"
  | "TEST_TRAFFIC_SHIFT"
  | "POST_TEST_TRAFFIC_SHIFT"
  | "PRE_PRODUCTION_TRAFFIC_SHIFT"
  | "PRODUCTION_TRAFFIC_SHIFT"
  | "POST_PRODUCTION_TRAFFIC_SHIFT";

export interface HookEvent<D = Record<string, unknown>> {
  executionId: string;
  lifecycleStage: LifecycleStage;
  resourceArn: string;
  executionDetails: {
    serviceArn: string;
    targetServiceRevisionArn: string;
    testTrafficWeights: Record<string, number>;
    productionTrafficWeights: Record<string, number>;
  };
  hookDetails?: D;
}

export type HookResponse<D = Record<string, unknown>> =
  | { hookStatus: "SUCCEEDED" | "FAILED" }
  | { hookStatus: "IN_PROGRESS"; callBackDelay?: number; hookDetails?: D };
