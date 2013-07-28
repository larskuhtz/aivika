
-- |
-- Module     : Simulation.Aivika.Observable
-- Copyright  : Copyright (c) 2009-2013, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.6.3
--
-- It defines an observable entity that has a value and signal at
-- which this value changes.
module Simulation.Aivika.Observable
       (Observable,
        readObservable,
        observableSignal) where

import Simulation.Aivika.Internal.Observable
