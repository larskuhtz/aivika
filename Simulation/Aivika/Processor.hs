
-- |
-- Module     : Simulation.Aivika.Processor
-- Copyright  : Copyright (c) 2009-2013, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.6.3
--
-- The processor of simulation data.
--
module Simulation.Aivika.Processor
       (-- * Processor Type
        Processor(..),
        -- * Creating Simple Processor
        simpleProcessor,
        statefulProcessor,
        -- * Specifying Identifier
        processorUsingId,
        -- * Buffer Processor
        bufferProcessor,
        bufferProcessorLoop,
        -- * Processing Queues
        queueProcessor,
        queueProcessorLoopMerging,
        queueProcessorLoopSeq,
        queueProcessorLoopParallel,
        -- * Parallelizing Processors
        processorParallel,
        processorQueuedParallel,
        processorPrioritisingOutputParallel,
        processorPrioritisingInputParallel,
        processorPrioritisingInputOutputParallel) where

import qualified Control.Category as C
import Control.Arrow

import Simulation.Aivika.Simulation
import Simulation.Aivika.Dynamics
import Simulation.Aivika.Event
import Simulation.Aivika.Cont
import Simulation.Aivika.Process
import Simulation.Aivika.Stream
import Simulation.Aivika.QueueStrategy

-- | Represents a processor of simulation data.
newtype Processor a b =
  Processor { runProcessor :: Stream a -> Stream b
              -- ^ Run the processor.
            }

instance C.Category Processor where

  id  = Processor id

  Processor x . Processor y = Processor (x . y)

-- The implementation is based on article
-- A New Notation for Arrows by Ross Paterson,
-- although my streams are different and they
-- already depend on the Process monad,
-- while the pure streams were considered in the
-- mentioned article.
instance Arrow Processor where

  arr = Processor . mapStream

  first (Processor f) =
    Processor $ \xys ->
    Cons $
    do (xs, ys) <- liftSimulation $ unzipStream xys
       runStream $ zipStreamSeq (f xs) ys

  second (Processor f) =
    Processor $ \xys ->
    Cons $
    do (xs, ys) <- liftSimulation $ unzipStream xys
       runStream $ zipStreamSeq xs (f ys)

  Processor f *** Processor g =
    Processor $ \xys ->
    Cons $
    do (xs, ys) <- liftSimulation $ unzipStream xys
       runStream $ zipStreamSeq (f xs) (g ys)

-- N.B.
-- Very probably, Processor is not ArrowLoop,
-- which would be natural as Process is not MonadFix,
-- for the discontinuous process is not irreversible
-- and the time flows in one direction only.
--
-- -- The implementation is based on article
-- -- A New Notation for Arrows by Ross Paterson,
-- -- although my streams are different and they
-- -- already depend on the Process monad,
-- -- while the pure streams were considered in the
-- -- mentioned article.
-- instance ArrowLoop Processor where
-- 
--   loop (Processor f) =
--     Processor $ \xs ->
--     Cons $
--     do Cons zs <- liftSimulation $
--                   simulationLoop (\(xs, ys) ->
--                                    unzipStream $ f $ zipStreamSeq xs ys) xs
--        zs
-- 
-- simulationLoop :: ((b, d) -> Simulation (c, d)) -> b -> Simulation c
-- simulationLoop f b =
--   mdo (c, d) <- f (b, d)
--       return c

-- The implementation is based on article
-- A New Notation for Arrows by Ross Paterson,
-- although my streams are different and they
-- already depend on the Process monad,
-- while the pure streams were considered in the
-- mentioned article.
instance ArrowChoice Processor where

  left (Processor f) =
    Processor $ \xs ->
    Cons $
    do ys <- liftSimulation $ memoStream xs
       runStream $ replaceLeftStream ys (f $ leftStream ys)

  right (Processor f) =
    Processor $ \xs ->
    Cons $
    do ys <- liftSimulation $ memoStream xs
       runStream $ replaceRightStream ys (f $ rightStream ys)

instance ArrowZero Processor where

  zeroArrow = Processor $ const emptyStream

instance ArrowPlus Processor where

  (Processor f) <+> (Processor g) =
    Processor $ \xs ->
    Cons $
    do [xs1, xs2] <- liftSimulation $ splitStream 2 xs
       runStream $ mergeStreams (f xs1) (g xs2)

-- These instances are meaningless:
-- 
-- instance SimulationLift (Processor a) where
--   liftSimulation = Processor . mapStreamM . const . liftSimulation
-- 
-- instance DynamicsLift (Processor a) where
--   liftDynamics = Processor . mapStreamM . const . liftDynamics
-- 
-- instance EventLift (Processor a) where
--   liftEvent = Processor . mapStreamM . const . liftEvent
-- 
-- instance ProcessLift (Processor a) where
--   liftProcess = Processor . mapStreamM . const    -- data first!

-- | Create a simple processor by the specified handling function
-- that runs the discontinuous process for each input value to get the output.
simpleProcessor :: (a -> Process b) -> Processor a b
simpleProcessor = Processor . mapStreamM

-- | Like 'simpleProcessor' but allows creating a processor that has a state
-- which is passed in to every new iteration.
statefulProcessor :: s -> ((s, a) -> Process (s, b)) -> Processor a b
statefulProcessor s f =
  Processor $ \xs -> Cons $ loop s xs where
    loop s xs =
      do (a, xs') <- runStream xs
         (s', b) <- f (s, a)
         return (b, Cons $ loop s' xs')

-- | Create a processor that will use the specified process identifier.
-- It can be useful to refer to the underlying 'Process' computation which
-- can be passivated, interrupted, canceled and so on. See also the
-- 'processUsingId' function for more details.
processorUsingId :: ProcessId -> Processor a b -> Processor a b
processorUsingId pid (Processor f) =
  Processor $ Cons . processUsingId pid . runStream . f

-- | Launches the specified processors in parallel consuming the same input
-- stream and producing a combined output stream.
--
-- If you don't know what the enqueue strategies to apply, then
-- you will probably need 'FCFS' for the both parameters, or
-- function 'processorParallel' that does namely this.
processorQueuedParallel :: (EnqueueStrategy si qi,
                            EnqueueStrategy so qo)
                           => si
                           -- ^ the strategy applied for enqueuing the input data
                           -> so
                           -- ^ the strategy applied for enqueuing the output data
                           -> [Processor a b]
                           -- ^ the processors to parallelize
                           -> Processor a b
                           -- ^ the parallelized processor
processorQueuedParallel si so ps =
  Processor $ \xs ->
  Cons $
  do let n = length ps
     input <- liftSimulation $ splitStreamQueuing si n xs
     let results = flip map (zip input ps) $ \(input, p) ->
           runProcessor p input
         output  = concatQueuedStreams so results
     runStream output

-- | Launches the specified processors in parallel using priorities for combining the output.
processorPrioritisingOutputParallel :: (EnqueueStrategy si qi,
                                        PriorityQueueStrategy so qo po)
                                       => si
                                       -- ^ the strategy applied for enqueuing the input data
                                       -> so
                                       -- ^ the strategy applied for enqueuing the output data
                                       -> [Processor a (po, b)]
                                       -- ^ the processors to parallelize
                                       -> Processor a b
                                       -- ^ the parallelized processor
processorPrioritisingOutputParallel si so ps =
  Processor $ \xs ->
  Cons $
  do let n = length ps
     input <- liftSimulation $ splitStreamQueuing si n xs
     let results = flip map (zip input ps) $ \(input, p) ->
           runProcessor p input
         output  = concatPriorityStreams so results
     runStream output

-- | Launches the specified processors in parallel using priorities for consuming the intput.
processorPrioritisingInputParallel :: (PriorityQueueStrategy si qi pi,
                                       EnqueueStrategy so qo)
                                      => si
                                      -- ^ the strategy applied for enqueuing the input data
                                      -> so
                                      -- ^ the strategy applied for enqueuing the output data
                                      -> [(Stream pi, Processor a b)]
                                      -- ^ the streams of input priorities and the processors
                                      -- to parallelize
                                      -> Processor a b
                                      -- ^ the parallelized processor
processorPrioritisingInputParallel si so ps =
  Processor $ \xs ->
  Cons $
  do input <- liftSimulation $ splitStreamPrioritising si (map fst ps) xs
     let results = flip map (zip input ps) $ \(input, (_, p)) ->
           runProcessor p input
         output  = concatQueuedStreams so results
     runStream output

-- | Launches the specified processors in parallel using priorities for consuming
-- the input and combining the output.
processorPrioritisingInputOutputParallel :: (PriorityQueueStrategy si qi pi,
                                             PriorityQueueStrategy so qo po)
                                            => si
                                            -- ^ the strategy applied for enqueuing the input data
                                            -> so
                                            -- ^ the strategy applied for enqueuing the output data
                                            -> [(Stream pi, Processor a (po, b))]
                                            -- ^ the streams of input priorities and the processors
                                            -- to parallelize
                                            -> Processor a b
                                            -- ^ the parallelized processor
processorPrioritisingInputOutputParallel si so ps =
  Processor $ \xs ->
  Cons $
  do input <- liftSimulation $ splitStreamPrioritising si (map fst ps) xs
     let results = flip map (zip input ps) $ \(input, (_, p)) ->
           runProcessor p input
         output  = concatPriorityStreams so results
     runStream output

-- | Launches the processors in parallel consuming the same input stream and producing
-- a combined output stream. This version applies the 'FCFS' strategy both for input
-- and output, which suits the most part of uses cases.
processorParallel :: [Processor a b] -> Processor a b
processorParallel = processorQueuedParallel FCFS FCFS

-- | Create a buffer processor, where the process from the first argument
-- consumes the input stream but the stream passed in as the second argument
-- and produced usually by some other process is returned as an output.
-- This kind of processor is very useful for modeling the queues.
bufferProcessor :: (Stream a -> Process ())
                   -- ^ a separate process to consume the input 
                   -> Stream b
                   -- ^ the resulting stream of data
                   -> Processor a b
bufferProcessor consume output =
  Processor $ \xs ->
  Cons $
  do spawnProcess CancelTogether (consume xs)
     runStream output

-- | Like 'bufferProcessor' but allows creating a loop when some items
-- can be returned for processing them again. It is very useful for
-- modeling the processors with queues and loop-backs.
bufferProcessorLoop :: (Stream a -> Stream c -> Process ())
                       -- ^ consume two streams: the input values of type @a@
                       -- and the values of type @c@ returned by the loop
                       -> Stream d
                       -- ^ the stream of data that may become results
                       -> Processor d (Either c b)
                       -- ^ process and then decide what values of type @c@
                       -- should be processed again
                       -> Processor a b
bufferProcessorLoop consume preoutput filter =
  Processor $ \xs ->
  Cons $
  do (reverted, output) <-
       liftSimulation $
       partitionEitherStream $
       runProcessor filter preoutput
     spawnProcess CancelTogether (consume xs reverted)
     runStream output

-- | Return a processor with help of which we can model the queue.
--
-- Although the function doesn't refer to the queue directly, its main use case
-- is namely a processing of the queue. The first argument should be the enqueueing
-- operation, while the second argument should be the opposite dequeueing operation.
--
-- The reason is as follows. There are many possible combinations how the queues
-- can be modeled. There is no sense to enumerate all them creating a separate function
-- for each case. We can just use combinators to define exactly what we need.
--
-- So, the queue can lose the input items if the queue is full, or the input process
-- can suspend while the queue is full, or we can use priorities for enqueueing,
-- storing and dequeueing the items in different combinations. There are so many use
-- cases!
--
-- There is a hope that this function along with other similar functions from this
-- module is sufficient to cover the most important cases. Even if it is not sufficient
-- then you can use a more generic function 'bufferProcessor' which this function is
-- based on. In case of need, you can even write your own function from scratch. It is
-- quite easy actually.
queueProcessor :: (a -> Process ())
                  -- ^ enqueue the input item and wait
                  -- while the queue is full if required
                  -- so that there were no hanging items
                  -> Process b
                  -- ^ dequeue an output item
                  -> Processor a b
                  -- ^ the buffering processor
queueProcessor enqueue dequeue =
  bufferProcessor
  (consumeStream enqueue)
  (repeatProcess dequeue)

-- | Like 'queueProcessor' creates a queue processor but allows creating
-- a loop when some items can be returned and added to the queue again.
-- Also it allows specifying how two input streams of data can be merged.
queueProcessorLoopMerging :: (Stream a -> Stream d -> Stream e)
                             -- ^ merge two streams: the input values of type @a@
                             -- and the values of type @d@ returned by the loop
                             -> (e -> Process ())
                             -- ^ enqueue the input item and wait
                             -- while the queue is full if required
                             -- so that there were no hanging items
                             -> Process c
                             -- ^ dequeue an item for the further processing
                             -> Processor c (Either d b)
                             -- ^ process and then decide what values of type @d@
                             -- should be processed again
                             -> Processor a b
                             -- ^ the buffering processor
queueProcessorLoopMerging merge enqueue dequeue =
  bufferProcessorLoop
  (\bs cs ->
    consumeStream enqueue $
    merge bs cs)
  (repeatProcess dequeue)

-- | Like 'queueProcessorLoopMerging' creates a queue processor and allows
-- creating a loop when some items can be returned and added to the queue again.
-- Only it sequentially merges two input streams of data: one stream
-- that come from the external source and another stream of data returned
-- by the loop. The first stream has a priority over the second one.
queueProcessorLoopSeq :: (a -> Process ())
                         -- ^ enqueue the input item and wait
                         -- while the queue is full if required
                         -- so that there were no hanging items
                         -> Process c
                         -- ^ dequeue an item for the further processing
                         -> Processor c (Either a b)
                         -- ^ process and then decide what values of type @a@
                         -- should be processed again
                         -> Processor a b
                         -- ^ the buffering processor
queueProcessorLoopSeq =
  queueProcessorLoopMerging mergeStreams

-- | Like 'queueProcessorLoopMerging' creates a queue processor and allows
-- creating a loop when some items can be returned and added to the queue again.
-- Only it runs two simultaneous processes to enqueue the input streams of data:
-- one stream that come from the external source and another stream of data returned
-- by the loop.
queueProcessorLoopParallel :: (a -> Process ())
                              -- ^ enqueue the input item and wait
                              -- while the queue is full if required
                              -- so that there were no hanging items
                              -> Process c
                              -- ^ dequeue an item for the further processing
                              -> Processor c (Either a b)
                              -- ^ process and then decide what values of type @a@
                              -- should be processed again
                              -> Processor a b
                              -- ^ the buffering processor
queueProcessorLoopParallel enqueue dequeue =
  bufferProcessorLoop
  (\bs cs ->
    do spawnProcess CancelTogether $
         consumeStream enqueue bs
       spawnProcess CancelTogether $
         consumeStream enqueue cs)
  (repeatProcess dequeue)
