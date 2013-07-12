
-- |
-- Module     : Simulation.Aivika.Dynamics.Random
-- Copyright  : Copyright (c) 2009-2013, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.6.3
--
-- Below are defined random functions that mostly return discrete processes. 
-- Literally, it means that the values are initially defined in integration 
-- time points and then they are passed to the 'discrete' function.
--

module Simulation.Aivika.Dynamics.Random 
       (newRandom, newNormal, normalGen) where

import System.Random
import Data.IORef
import Control.Monad.Trans

import Simulation.Aivika.Dynamics
import Simulation.Aivika.Dynamics.Simulation
import Simulation.Aivika.Dynamics.Base

-- | Return the uniform random numbers in the integration time points.
newRandom :: Dynamics Double     -- ^ minimum
             -> Dynamics Double  -- ^ maximum
             -> Simulation (Dynamics Double)
newRandom min max =
  umemo0 $ do
    x <- liftIO $ getStdRandom random
    min + return x * (max - min)
     
-- | Return the normal random numbers in the integration time points.
newNormal :: Dynamics Double     -- ^ mean
             -> Dynamics Double  -- ^ variance
             -> Simulation (Dynamics Double)
newNormal mu nu =
  do g <- liftIO normalGen
     umemo0 $ do
       x <- liftIO g
       mu + return x * nu

-- | Normal random number generator with mean 0 and variance 1.
normalGen :: IO (IO Double)
normalGen =
  do nextRef <- newIORef 0.0
     flagRef <- newIORef False
     xi1Ref  <- newIORef 0.0
     xi2Ref  <- newIORef 0.0
     psiRef  <- newIORef 0.0
     let loop =
           do psi <- readIORef psiRef
              if (psi >= 1.0) || (psi == 0.0)
                then do g1 <- getStdRandom random
                        g2 <- getStdRandom random
                        let xi1 = 2.0 * g1 - 1.0
                            xi2 = 2.0 * g2 - 1.0
                            psi = xi1 * xi1 + xi2 * xi2
                        writeIORef xi1Ref xi1
                        writeIORef xi2Ref xi2
                        writeIORef psiRef psi
                        loop
                else writeIORef psiRef $ sqrt (- 2.0 * log psi / psi)
     return $
       do flag <- readIORef flagRef
          if flag
            then do writeIORef flagRef False
                    readIORef nextRef
            else do writeIORef xi1Ref 0.0
                    writeIORef xi2Ref 0.0
                    writeIORef psiRef 0.0
                    loop
                    xi1 <- readIORef xi1Ref
                    xi2 <- readIORef xi2Ref
                    psi <- readIORef psiRef
                    writeIORef flagRef True
                    writeIORef nextRef $ xi2 * psi
                    return $ xi1 * psi
