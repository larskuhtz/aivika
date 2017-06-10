
-- |
-- Module     : Simulation.Aivika.Internal.Arrival
-- Copyright  : Copyright (c) 2009-2017, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 8.0.1
--
-- This module defines the types and functions for working with the events
-- that can represent something that arrive from outside the model, or
-- represent other things which computation is delayed and hence is not synchronized.
--
-- Therefore, the additional information is provided about the time and delay of arrival.

module Simulation.Aivika.Internal.Arrival
       (Arrival(..)) where

import Simulation.Aivika.Event

-- | It defines when an event has arrived, usually generated by some random stream.
--
-- Such events should arrive one by one without time lag in the following sense
-- that the model should start awaiting the next event exactly in that time
-- when the previous event has arrived.
--
-- Another use case is a situation when the actual event is not synchronized with
-- the 'Event' computation, being synchronized with the event queue, nevertheless.
-- Then the arrival is used for providing the additional information about the time
-- at which the event had been actually arrived.
data Arrival a =
  Arrival { arrivalValue :: a,
            -- ^ the data we received with the event
            arrivalTime :: Double,
            -- ^ the simulation time at which the event has arrived
            arrivalDelay :: Maybe Double
            -- ^ the delay time which has passed from the time of
            -- arriving the previous event
          } deriving (Eq, Ord, Show)
