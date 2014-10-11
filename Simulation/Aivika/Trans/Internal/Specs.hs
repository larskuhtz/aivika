
{-# LANGUAGE TypeFamilies #-}

-- |
-- Module     : Simulation.Aivika.Trans.Internal.Specs
-- Copyright  : Copyright (c) 2009-2014, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.8.3
--
-- It defines the simulation specs and related stuff.
module Simulation.Aivika.Trans.Internal.Specs
       (Specs(..),
        Method(..),
        Run(..),
        Point(..),
        EventQueueable(..),
        EventQueue(..),
        basicTime,
        integIterationBnds,
        integIterationHiBnd,
        integIterationLoBnd,
        integPhaseBnds,
        integPhaseHiBnd,
        integPhaseLoBnd,
        integTimes,
        integPoints,
        integStartPoint,
        integStopPoint,
        pointAt) where

import Data.IORef

import Simulation.Aivika.Trans.Session
import Simulation.Aivika.Trans.Generator
import qualified Simulation.Aivika.Trans.PriorityQueue as PQ

-- | It defines the simulation specs.
data Specs m = Specs { spcStartTime :: Double,    -- ^ the start time
                       spcStopTime :: Double,     -- ^ the stop time
                       spcDT :: Double,           -- ^ the integration time step
                       spcMethod :: Method,       -- ^ the integration method
                       spcGeneratorType :: GeneratorType m
                       -- ^ the type of the random number generator
                     }

-- | It defines the integration method.
data Method = Euler          -- ^ Euler's method
            | RungeKutta2    -- ^ the 2nd order Runge-Kutta method
            | RungeKutta4    -- ^ the 4th order Runge-Kutta method
            deriving (Eq, Ord, Show)

-- | It indentifies the simulation run.
data Run m = Run { runSpecs :: Specs m,            -- ^ the simulation specs
                   runSession :: Session m,        -- ^ the simulation session
                   runIndex :: Int,       -- ^ the current simulation run index
                   runCount :: Int,       -- ^ the total number of runs in this experiment
                   runEventQueue :: EventQueue m,  -- ^ the event queue
                   runGenerator :: Generator m     -- ^ the random number generator
                 }

-- | It defines the simulation point appended with the additional information.
data Point m = Point { pointSpecs :: Specs m,      -- ^ the simulation specs
                       pointRun :: Run m,          -- ^ the simulation run
                       pointTime :: Double,        -- ^ the current time
                       pointIteration :: Int,      -- ^ the current iteration
                       pointPhase :: Int           -- ^ the current phase
                     }

-- | A type class of monads within which the event queues are defined.
class EventQueueable m where

  -- | It represents the event queue.
  data EventQueue m :: *

  -- | Create a new event queue by the specified specs with simulation session.
  newEventQueue :: Session m -> Specs m -> m (EventQueue m)

instance EventQueueable IO where

  data EventQueue IO =
    EventQueue { queuePQ :: PQ.PriorityQueue (Point IO -> IO ()),
                 -- ^ the underlying priority queue
                 queueBusy :: IORef Bool,
                 -- ^ whether the queue is currently processing events
                 queueTime :: IORef Double
                 -- ^ the actual time of the event queue
               }
  
  newEventQueue session specs = 
    do f <- newIORef False
       t <- newIORef $ spcStartTime specs
       pq <- PQ.newQueue
       return EventQueue { queuePQ   = pq,
                           queueBusy = f,
                           queueTime = t }

-- | Returns the integration iterations starting from zero.
integIterations :: Specs m -> [Int]
integIterations sc = [i1 .. i2] where
  i1 = integIterationLoBnd sc
  i2 = integIterationHiBnd sc

-- | Returns the first and last integration iterations.
integIterationBnds :: Specs m -> (Int, Int)
integIterationBnds sc = (i1, i2) where
  i1 = integIterationLoBnd sc
  i2 = integIterationHiBnd sc

-- | Returns the first integration iteration, i.e. zero.
integIterationLoBnd :: Specs m -> Int
integIterationLoBnd sc = 0

-- | Returns the last integration iteration.
integIterationHiBnd :: Specs m -> Int
integIterationHiBnd sc =
  let n = round ((spcStopTime sc - 
                  spcStartTime sc) / spcDT sc)
  in if n < 0
     then
       error $
       "Either the simulation specs are incorrect, " ++
       "or a step time is too small, because of which " ++
       "a floating point overflow occurred on 32-bit Haskell implementation."
     else n

-- | Returns the phases for the specified simulation specs starting from zero.
integPhases :: Specs m -> [Int]
integPhases sc = 
  case spcMethod sc of
    Euler -> [0]
    RungeKutta2 -> [0, 1]
    RungeKutta4 -> [0, 1, 2, 3]

-- | Returns the first and last integration phases.
integPhaseBnds :: Specs m -> (Int, Int)
integPhaseBnds sc = 
  case spcMethod sc of
    Euler -> (0, 0)
    RungeKutta2 -> (0, 1)
    RungeKutta4 -> (0, 3)

-- | Returns the first integration phase, i.e. zero.
integPhaseLoBnd :: Specs m -> Int
integPhaseLoBnd sc = 0
                  
-- | Returns the last integration phase, 0 for Euler's method, 1 for RK2 and 3 for RK4.
integPhaseHiBnd :: Specs m -> Int
integPhaseHiBnd sc = 
  case spcMethod sc of
    Euler -> 0
    RungeKutta2 -> 1
    RungeKutta4 -> 3

-- | Returns a simulation time for the integration point specified by 
-- the specs, iteration and phase.
basicTime :: Specs m -> Int -> Int -> Double
{-# INLINE basicTime #-}
basicTime sc n ph =
  if ph < 0 then 
    error "Incorrect phase: basicTime"
  else
    spcStartTime sc + n' * spcDT sc + delta (spcMethod sc) ph 
      where n' = fromIntegral n
            delta Euler       0 = 0
            delta RungeKutta2 0 = 0
            delta RungeKutta2 1 = spcDT sc
            delta RungeKutta4 0 = 0
            delta RungeKutta4 1 = spcDT sc / 2
            delta RungeKutta4 2 = spcDT sc / 2
            delta RungeKutta4 3 = spcDT sc

-- | Return the integration time values.
integTimes :: Specs m -> [Double]
integTimes sc = map t [nl .. nu]
  where (nl, nu) = integIterationBnds sc
        t n = basicTime sc n 0

-- | Return the integration time points.
integPoints :: Run m -> [Point m]
integPoints r = points
  where sc = runSpecs r
        (nl, nu) = integIterationBnds sc
        points   = map point [nl .. nu]
        point n  = Point { pointSpecs = sc,
                           pointRun = r,
                           pointTime = basicTime sc n 0,
                           pointIteration = n,
                           pointPhase = 0 }

-- | Return the start time point.
integStartPoint :: Run m -> Point m
integStartPoint r = point nl
  where sc = runSpecs r
        (nl, nu) = integIterationBnds sc
        point n  = Point { pointSpecs = sc,
                           pointRun = r,
                           pointTime = basicTime sc n 0,
                           pointIteration = n,
                           pointPhase = 0 }

-- | Return the stop time point.
integStopPoint :: Run m -> Point m
integStopPoint r = point nu
  where sc = runSpecs r
        (nl, nu) = integIterationBnds sc
        point n  = Point { pointSpecs = sc,
                           pointRun = r,
                           pointTime = basicTime sc n 0,
                           pointIteration = n,
                           pointPhase = 0 }

-- | Return the point at the specified time.
pointAt :: Run m -> Double -> Point m
{-# INLINABLE pointAt #-}
pointAt r t = p
  where sc = runSpecs r
        t0 = spcStartTime sc
        dt = spcDT sc
        n  = fromIntegral $ floor ((t - t0) / dt)
        p = Point { pointSpecs = sc,
                    pointRun = r,
                    pointTime = t,
                    pointIteration = n,
                    pointPhase = -1 }
