
-- |
-- Module     : Simulation.Aivika.Results.Locale.English
-- Copyright  : Copyright (c) 2009-2017, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 8.0.1
--
-- The English localisation.
--
module Simulation.Aivika.Results.Locale.English
       (englishResultLocalisation) where

import Simulation.Aivika.Results.Locale.Types

-- | The English localisation.
englishResultLocalisation :: ResultLocalisation
englishResultLocalisation = ResultLocalisation englishResultDescription englishResultTitle

-- | The English localisation of the simulation results.
englishResultDescription :: ResultId -> ResultDescription
englishResultDescription TimeId = "simulation time"
englishResultDescription VectorId = "vector"
englishResultDescription (VectorItemId x) = "item #" ++ x
englishResultDescription SamplingStatsId = "statistics summary"
englishResultDescription SamplingStatsCountId = "count"
englishResultDescription SamplingStatsMinId = "minimum"
englishResultDescription SamplingStatsMaxId = "maximum"
englishResultDescription SamplingStatsMeanId = "mean"
englishResultDescription SamplingStatsMean2Id = "mean square"
englishResultDescription SamplingStatsVarianceId = "variance"
englishResultDescription SamplingStatsDeviationId = "deviation"
englishResultDescription TimingStatsId = "timing statistics"
englishResultDescription TimingStatsCountId = "count"
englishResultDescription TimingStatsMinId = "minimum"
englishResultDescription TimingStatsMaxId = "maximum"
englishResultDescription TimingStatsMeanId = "mean"
englishResultDescription TimingStatsVarianceId = "variance"
englishResultDescription TimingStatsDeviationId = "deviation"
englishResultDescription TimingStatsMinTimeId = "the time of minimum"
englishResultDescription TimingStatsMaxTimeId = "the time of maximum"
englishResultDescription TimingStatsStartTimeId = "the start time"
englishResultDescription TimingStatsLastTimeId = "the last time"
englishResultDescription TimingStatsSumId = "sum"
englishResultDescription TimingStatsSum2Id = "sum square"
englishResultDescription SamplingCounterId = "counter"
englishResultDescription SamplingCounterValueId = "current value"
englishResultDescription SamplingCounterStatsId = "statistics"
englishResultDescription TimingCounterId = "timing counter"
englishResultDescription TimingCounterValueId = "current value"
englishResultDescription TimingCounterStatsId = "statistics"
englishResultDescription FiniteQueueId = "the finite queue"
englishResultDescription InfiniteQueueId = "the infinite queue"
englishResultDescription EnqueueStrategyId = "the enqueueing strategy"
englishResultDescription EnqueueStoringStrategyId = "the storing strategy"
englishResultDescription DequeueStrategyId = "the dequeueing strategy"
englishResultDescription QueueNullId = "is the queue empty?"
englishResultDescription QueueFullId = "is the queue full?"
englishResultDescription QueueMaxCountId = "the queue capacity"
englishResultDescription QueueCountId = "the current queue size"
englishResultDescription QueueCountStatsId = "the queue size statistics"
englishResultDescription EnqueueCountId = "a total number of attempts to enqueue the items"
englishResultDescription EnqueueLostCountId = "a total number of the lost items when trying to enqueue"
englishResultDescription EnqueueStoreCountId = "a total number of the stored items"
englishResultDescription DequeueCountId = "a total number of requests for dequeueing"
englishResultDescription DequeueExtractCountId = "a total number of the dequeued items"
englishResultDescription QueueLoadFactorId = "the queue load (its size divided by its capacity)"
englishResultDescription EnqueueRateId = "how many attempts to enqueue per time?"
englishResultDescription EnqueueStoreRateId = "how many items were stored per time?"
englishResultDescription DequeueRateId = "how many requests for dequeueing per time?"
englishResultDescription DequeueExtractRateId = "how many items were dequeued per time?"
englishResultDescription QueueWaitTimeId = "the wait time (stored -> dequeued)"
englishResultDescription QueueTotalWaitTimeId = "the total wait time (tried to enqueue -> dequeued)"
englishResultDescription EnqueueWaitTimeId = "the enqueue wait time (tried to enqueue -> stored)"
englishResultDescription DequeueWaitTimeId = "the dequeue wait time (requested for dequeueing -> dequeued)"
englishResultDescription QueueRateId = "the average queue rate (= queue size / wait time)"
englishResultDescription ArrivalTimerId = "how long the arrivals are processed?"
englishResultDescription ArrivalProcessingTimeId = "the processing time of arrivals"
englishResultDescription ServerId = "the server"
englishResultDescription ServerInitStateId = "the initial state"
englishResultDescription ServerStateId = "the current state"
englishResultDescription ServerTotalInputWaitTimeId = "the total time spent while waiting for input"
englishResultDescription ServerTotalProcessingTimeId = "the total time spent on actual processing the tasks"
englishResultDescription ServerTotalOutputWaitTimeId = "the total time spent on delivering the output"
englishResultDescription ServerTotalPreemptionTimeId = "the total time spent being preempted"
englishResultDescription ServerInputWaitTimeId = "the time spent while waiting for input"
englishResultDescription ServerProcessingTimeId = "the time spent on processing the tasks"
englishResultDescription ServerOutputWaitTimeId = "the time spent on delivering the output"
englishResultDescription ServerPreemptionTimeId = "the time spent being preempted"
englishResultDescription ServerInputWaitFactorId = "the relative time spent while waiting for input (from 0 to 1)"
englishResultDescription ServerProcessingFactorId = "the relative time spent on processing the tasks (from 0 to 1)"
englishResultDescription ServerOutputWaitFactorId = "the relative time spent on delivering the output (from 0 to 1)"
englishResultDescription ServerPreemptionFactorId = "the relative time spent being preempted (from 0 to 1)"
englishResultDescription ActivityId = "the activity"
englishResultDescription ActivityInitStateId = "the initial state"
englishResultDescription ActivityStateId = "the current state"
englishResultDescription ActivityTotalUtilisationTimeId = "the total time of utilisation"
englishResultDescription ActivityTotalIdleTimeId = "the total idle time"
englishResultDescription ActivityTotalPreemptionTimeId = "the total time of preemption"
englishResultDescription ActivityUtilisationTimeId = "the utilisation time"
englishResultDescription ActivityIdleTimeId = "the idle time"
englishResultDescription ActivityPreemptionTimeId = "the preemption time"
englishResultDescription ActivityUtilisationFactorId = "the relative utilisation time (from 0 to 1)"
englishResultDescription ActivityIdleFactorId = "the relative idle time (from 0 to 1)"
englishResultDescription ActivityPreemptionFactorId = "the relative preemption time (from 0 to 1)"
englishResultDescription ResourceId = "the resource"
englishResultDescription ResourceCountId = "the current available count"
englishResultDescription ResourceCountStatsId = "the available count statistics"
englishResultDescription ResourceUtilisationCountId = "the current utilisation count"
englishResultDescription ResourceUtilisationCountStatsId = "the utilisation count statistics"
englishResultDescription ResourceQueueCountId = "the current queue length"
englishResultDescription ResourceQueueCountStatsId = "the queue length statistics"
englishResultDescription ResourceTotalWaitTimeId = "the total wait time"
englishResultDescription ResourceWaitTimeId = "the wait time"
englishResultDescription OperationId = "the operation"
englishResultDescription OperationTotalUtilisationTimeId = "the total time of utilisation"
englishResultDescription OperationTotalPreemptionTimeId = "the total time of preemption"
englishResultDescription OperationUtilisationTimeId = "the utilisation time"
englishResultDescription OperationPreemptionTimeId = "the preemption time"
englishResultDescription OperationUtilisationFactorId = "the relative utilisation time (from 0 to 1)"
englishResultDescription OperationPreemptionFactorId = "the relative preemption time (from 0 to 1)"
englishResultDescription (UserDefinedResultId m) = userDefinedResultDescription m
englishResultDescription (LocalisedResultId m) =
  lookupResultLocalisation englishResultLocale (localisedResultDescriptions m)

-- | The English localisation of titles.
englishResultTitle :: ResultId -> ResultDescription
englishResultTitle TimeId = "time"
englishResultTitle VectorId = "vector"
englishResultTitle (VectorItemId x) = "item #" ++ x
englishResultTitle SamplingStatsId = "stats"
englishResultTitle SamplingStatsCountId = "count"
englishResultTitle SamplingStatsMinId = "minimum"
englishResultTitle SamplingStatsMaxId = "maximum"
englishResultTitle SamplingStatsMeanId = "mean"
englishResultTitle SamplingStatsMean2Id = "mean square"
englishResultTitle SamplingStatsVarianceId = "variance"
englishResultTitle SamplingStatsDeviationId = "deviation"
englishResultTitle TimingStatsId = "time-persistent stats"
englishResultTitle TimingStatsCountId = "count"
englishResultTitle TimingStatsMinId = "minimum"
englishResultTitle TimingStatsMaxId = "maximum"
englishResultTitle TimingStatsMeanId = "mean"
englishResultTitle TimingStatsVarianceId = "variance"
englishResultTitle TimingStatsDeviationId = "deviation"
englishResultTitle TimingStatsMinTimeId = "time of minimum"
englishResultTitle TimingStatsMaxTimeId = "time of maximum"
englishResultTitle TimingStatsStartTimeId = "start time"
englishResultTitle TimingStatsLastTimeId = "last time"
englishResultTitle TimingStatsSumId = "sum"
englishResultTitle TimingStatsSum2Id = "sum square"
englishResultTitle SamplingCounterId = "stats counter"
englishResultTitle SamplingCounterValueId = "current value"
englishResultTitle SamplingCounterStatsId = "stats"
englishResultTitle TimingCounterId = "time-persistent stats counter"
englishResultTitle TimingCounterValueId = "current value"
englishResultTitle TimingCounterStatsId = "time-persistent stats"
englishResultTitle FiniteQueueId = "bounded queue"
englishResultTitle InfiniteQueueId = "unbounded queue"
englishResultTitle EnqueueStrategyId = "enqueu strategy"
englishResultTitle EnqueueStoringStrategyId = "storing strategy"
englishResultTitle DequeueStrategyId = "dequeue strategy"
englishResultTitle QueueNullId = "empty queue?"
englishResultTitle QueueFullId = "full queue?"
englishResultTitle QueueMaxCountId = "queue capacity"
englishResultTitle QueueCountId = "queue length"
englishResultTitle QueueCountStatsId = "queue length stats"
englishResultTitle EnqueueCountId = "enqueue request count"
englishResultTitle EnqueueLostCountId = "failed enqueue count"
englishResultTitle EnqueueStoreCountId = "fulfilled enqueue count"
englishResultTitle DequeueCountId = "dequeue request count"
englishResultTitle DequeueExtractCountId = "fulfilled dequeue count"
englishResultTitle QueueLoadFactorId = "queue load"
englishResultTitle EnqueueRateId = "enqueue request rate"
englishResultTitle EnqueueStoreRateId = "fulfilled enqueue rate"
englishResultTitle DequeueRateId = "dequeue request rate"
englishResultTitle DequeueExtractRateId = "fulfilled dequeue rate"
englishResultTitle QueueWaitTimeId = "wait time"
englishResultTitle QueueTotalWaitTimeId = "total wait time"
englishResultTitle EnqueueWaitTimeId = "enqueue wait time"
englishResultTitle DequeueWaitTimeId = "dequeue wait time"
englishResultTitle QueueRateId = "queue rate"
englishResultTitle ArrivalTimerId = "measures arrival processing time"
englishResultTitle ArrivalProcessingTimeId = "arrival processing time"
englishResultTitle ServerId = "server"
englishResultTitle ServerInitStateId = "initial state"
englishResultTitle ServerStateId = "current state"
englishResultTitle ServerTotalInputWaitTimeId = "total input wait time"
englishResultTitle ServerTotalProcessingTimeId = "total processing time"
englishResultTitle ServerTotalOutputWaitTimeId = "total output wait time"
englishResultTitle ServerTotalPreemptionTimeId = "total preemption time"
englishResultTitle ServerInputWaitTimeId = "input wait time"
englishResultTitle ServerProcessingTimeId = "processing time"
englishResultTitle ServerOutputWaitTimeId = "output wait time"
englishResultTitle ServerPreemptionTimeId = "preemption time"
englishResultTitle ServerInputWaitFactorId = "relative input wait time"
englishResultTitle ServerProcessingFactorId = "relative processing time"
englishResultTitle ServerOutputWaitFactorId = "relative output wait time"
englishResultTitle ServerPreemptionFactorId = "relative preemption time"
englishResultTitle ActivityId = "activity"
englishResultTitle ActivityInitStateId = "initial state"
englishResultTitle ActivityStateId = "current state"
englishResultTitle ActivityTotalUtilisationTimeId = "total utilisation time"
englishResultTitle ActivityTotalIdleTimeId = "total idle time"
englishResultTitle ActivityTotalPreemptionTimeId = "total preemption time"
englishResultTitle ActivityUtilisationTimeId = "utilisation time"
englishResultTitle ActivityIdleTimeId = "idle time"
englishResultTitle ActivityPreemptionTimeId = "preemption time"
englishResultTitle ActivityUtilisationFactorId = "relative utilisation time"
englishResultTitle ActivityIdleFactorId = "relative idle time"
englishResultTitle ActivityPreemptionFactorId = "relative preemption time"
englishResultTitle ResourceId = "resource"
englishResultTitle ResourceCountId = "content"
englishResultTitle ResourceCountStatsId = "content stats"
englishResultTitle ResourceUtilisationCountId = "utilisation count"
englishResultTitle ResourceUtilisationCountStatsId = "utilisation count stats"
englishResultTitle ResourceQueueCountId = "queue length"
englishResultTitle ResourceQueueCountStatsId = "queue length stats"
englishResultTitle ResourceTotalWaitTimeId = "total wait time"
englishResultTitle ResourceWaitTimeId = "wait time"
englishResultTitle OperationId = "operation"
englishResultTitle OperationTotalUtilisationTimeId = "total utilisation time"
englishResultTitle OperationTotalPreemptionTimeId = "total preemption time"
englishResultTitle OperationUtilisationTimeId = "utilisation time"
englishResultTitle OperationPreemptionTimeId = "preemption time"
englishResultTitle OperationUtilisationFactorId = "relative utilisation time"
englishResultTitle OperationPreemptionFactorId = "relative preemption time"
englishResultTitle (UserDefinedResultId m) = userDefinedResultTitle m
englishResultTitle (LocalisedResultId m) =
  lookupResultLocalisation englishResultLocale (localisedResultTitles m)
