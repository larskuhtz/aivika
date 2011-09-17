
{-# LANGUAGE FlexibleContexts #-}

-- |
-- Module     : Simulation.Aivika.Dynamics.Memo
-- Copyright  : Copyright (c) 2009-2011, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.0.3
--
-- This module defines memo functions. The memoization creates such processes, 
-- which values are defined and then stored in the cache for the integration 
-- points. Then these values are interpolated in other time points.
--

module Simulation.Aivika.Dynamics.Memo
       (memo,
        umemo,
        memo0,
        umemo0,
        iterateD) where

import Data.Array
import Data.Array.IO
import Data.IORef
import Control.Monad

import Simulation.Aivika.Dynamics
import Simulation.Aivika.Dynamics.Base

newMemoArray_ :: Ix i => (i, i) -> IO (IOArray i e)
newMemoArray_ = newArray_

newMemoUArray_ :: (MArray IOUArray e IO, Ix i) => (i, i) -> IO (IOUArray i e)
newMemoUArray_ = newArray_

-- | Memoize and order the computation in the integration time points using 
-- the interpolation that knows of the Runge-Kutta method.
memo :: Dynamics e -> Dynamics (Dynamics e)
{-# INLINE memo #-}
memo (Dynamics m) = 
  Dynamics $ \p ->
  do let sc = pointSpecs p
         (phl, phu) = phaseBnds sc
         (nl, nu)   = iterationBnds sc
     arr   <- newMemoArray_ ((phl, nl), (phu, nu))
     nref  <- newIORef 0
     phref <- newIORef 0
     let r p = 
           do let sc  = pointSpecs p
                  n   = pointIteration p
                  ph  = pointPhase p
                  phu = phaseHiBnd sc 
                  loop n' ph' = 
                    if (n' > n) || ((n' == n) && (ph' > ph)) 
                    then 
                      readArray arr (ph, n)
                    else 
                      let p' = p { pointIteration = n', pointPhase = ph',
                                   pointTime = basicTime sc n' ph' }
                      in do a <- m p'
                            a `seq` writeArray arr (ph', n') a
                            if ph' >= phu 
                              then do writeIORef phref 0
                                      writeIORef nref (n' + 1)
                                      loop (n' + 1) 0
                              else do writeIORef phref (ph' + 1)
                                      loop n' (ph' + 1)
              n'  <- readIORef nref
              ph' <- readIORef phref
              loop n' ph'
     return $ interpolate $ Dynamics r

-- | This is a more efficient version the 'memo' function which uses 
-- an unboxed array to store the values.
umemo :: (MArray IOUArray e IO) => Dynamics e -> Dynamics (Dynamics e)
{-# INLINE umemo #-}
umemo (Dynamics m) = 
  Dynamics $ \p ->
  do let sc = pointSpecs p
         (phl, phu) = phaseBnds sc
         (nl, nu)   = iterationBnds sc
     arr   <- newMemoUArray_ ((phl, nl), (phu, nu))
     nref  <- newIORef 0
     phref <- newIORef 0
     let r p =
           do let sc  = pointSpecs p
                  n   = pointIteration p
                  ph  = pointPhase p
                  phu = phaseHiBnd sc 
                  loop n' ph' = 
                    if (n' > n) || ((n' == n) && (ph' > ph)) 
                    then 
                      readArray arr (ph, n)
                    else 
                      let p' = p { pointIteration = n', 
                                   pointPhase = ph',
                                   pointTime = basicTime sc n' ph' }
                      in do a <- m p'
                            a `seq` writeArray arr (ph', n') a
                            if ph' >= phu 
                              then do writeIORef phref 0
                                      writeIORef nref (n' + 1)
                                      loop (n' + 1) 0
                              else do writeIORef phref (ph' + 1)
                                      loop n' (ph' + 1)
              n'  <- readIORef nref
              ph' <- readIORef phref
              loop n' ph'
     return $ interpolate $ Dynamics r

-- | Memoize and order the computation in the integration time points using 
-- the 'discrete' interpolation. It consumes less memory than the 'memo'
-- function but it is not aware of the Runge-Kutta method. There is a subtle
-- difference when we request for values in the intermediate time points
-- that are used by this method to integrate. In general case you should 
-- prefer the 'memo0' function above 'memo'.
memo0 :: Dynamics e -> Dynamics (Dynamics e)
{-# INLINE memo0 #-}
memo0 (Dynamics m) = 
  Dynamics $ \p ->
  do let sc   = pointSpecs p
         bnds = iterationBnds sc
     arr  <- newMemoArray_ bnds
     nref <- newIORef 0
     let r p =
           do let sc = pointSpecs p
                  n  = pointIteration p
                  loop n' = 
                    if n' > n
                    then 
                      readArray arr n
                    else 
                      let p' = p { pointIteration = n', pointPhase = 0,
                                   pointTime = basicTime sc n' 0 }
                      in do a <- m p'
                            a `seq` writeArray arr n' a
                            writeIORef nref (n' + 1)
                            loop (n' + 1)
              n' <- readIORef nref
              loop n'
     return $ discrete $ Dynamics r

-- | This is a more efficient version the 'memo0' function which uses 
-- an unboxed array to store the values.
umemo0 :: (MArray IOUArray e IO) => Dynamics e -> Dynamics (Dynamics e)
{-# INLINE umemo0 #-}
umemo0 (Dynamics m) = 
  Dynamics $ \p ->
  do let sc   = pointSpecs p
         bnds = iterationBnds sc
     arr  <- newMemoUArray_ bnds
     nref <- newIORef 0
     let r p =
           do let sc = pointSpecs p
                  n  = pointIteration p
                  loop n' = 
                    if n' > n
                    then 
                      readArray arr n
                    else 
                      let p' = p { pointIteration = n', pointPhase = 0,
                                   pointTime = basicTime sc n' 0 }
                      in do a <- m p'
                            a `seq` writeArray arr n' a
                            writeIORef nref (n' + 1)
                            loop (n' + 1)
              n' <- readIORef nref
              loop n'
     return $ discrete $ Dynamics r

-- | Iterate sequentially the dynamic process with side effects in 
-- the integration time points. It is equivalent to a call of the
-- @memo0@ function but significantly more efficient, for the array 
-- is not created.
iterateD :: Dynamics () -> Dynamics (Dynamics ())
{-# INLINE iterateD #-}
iterateD (Dynamics m) = 
  Dynamics $ \p ->
  do let sc = pointSpecs p
     nref <- newIORef 0
     let r p =
           do let sc = pointSpecs p
                  n  = pointIteration p
                  loop n' = 
                    unless (n' > n) $
                    let p' = p { pointIteration = n', pointPhase = 0,
                                 pointTime = basicTime sc n' 0 }
                    in do a <- m p'
                          a `seq` writeIORef nref (n' + 1)
                          loop (n' + 1)
              n' <- readIORef nref
              loop n'
     return $ discrete $ Dynamics r
