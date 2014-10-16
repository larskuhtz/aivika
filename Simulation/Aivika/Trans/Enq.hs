
-- |
-- Module     : Simulation.Aivika.Trans.Enq
-- Copyright  : Copyright (c) 2009-2014, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.8.3
--
-- It defines a type class of simulation monads that allow enqueueing the events.
--
module Simulation.Aivika.Trans.Enq
       (Enq(..)) where

import Simulation.Aivika.Trans.Comp
