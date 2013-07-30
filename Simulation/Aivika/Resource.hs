
-- |
-- Module     : Simulation.Aivika.Resource
-- Copyright  : Copyright (c) 2009-2013, David Sorokin <david.sorokin@gmail.com>
-- License    : BSD3
-- Maintainer : David Sorokin <david.sorokin@gmail.com>
-- Stability  : experimental
-- Tested with: GHC 7.6.3
--
-- This module defines the resource which can be acquired and 
-- then released by the discontinuous process 'Process'.
-- The resource can be either limited by the upper bound
-- (run-time check), or it can have no upper bound. The latter
-- is useful for modeling the infinite queue, for example.
--
module Simulation.Aivika.Resource
       (FCFSResource,
        LCFSResource,
        SIROResource,
        PriorityResource,
        Resource,
        newFCFSResource,
        newFCFSResourceWithMaxCount,
        newLCFSResource,
        newLCFSResourceWithMaxCount,
        newSIROResource,
        newSIROResourceWithMaxCount,
        newPriorityResource,
        newPriorityResourceWithMaxCount,
        newResource,
        newResourceWithMaxCount,
        resourceStrategy,
        resourceMaxCount,
        resourceCount,
        requestResource,
        requestResourceWithPriority,
        tryRequestResourceWithinEvent,
        releaseResource,
        releaseResourceWithinEvent,
        usingResource,
        usingResourceWithPriority) where

import Data.IORef
import Control.Monad
import Control.Monad.Trans

import Simulation.Aivika.Internal.Specs
import Simulation.Aivika.Internal.Simulation
import Simulation.Aivika.Internal.Event
import Simulation.Aivika.Internal.Cont
import Simulation.Aivika.Internal.Process
import Simulation.Aivika.QueueStrategy

import qualified Simulation.Aivika.DoubleLinkedList as DLL 
import qualified Simulation.Aivika.Vector as V
import qualified Simulation.Aivika.PriorityQueue as PQ

-- | The ordinary FCFS (First Come - First Serviced) resource.
type FCFSResource = Resource FCFS DLL.DoubleLinkedList

-- | The ordinary LCFS (Last Come - First Serviced) resource.
type LCFSResource = Resource LCFS DLL.DoubleLinkedList

-- | The SIRO (Serviced in Random Order) resource.
type SIROResource = Resource SIRO V.Vector

-- | The resource with static priorities.
type PriorityResource = Resource StaticPriorities PQ.PriorityQueue

-- | Represents the resource with strategy @s@ applied for queuing the requests.
-- The @q@ type is dependent and it is usually derived automatically.
data Resource s q = 
  Resource { resourceStrategy :: s,
             -- ^ Return the strategy applied for queuing the requests.
             resourceMaxCount :: Maybe Int,
             -- ^ Return the maximum count of the resource, where 'Nothing'
             -- means that the resource has no upper bound.
             resourceCountRef :: IORef Int, 
             resourceWaitList :: q (ContParams ())}

instance Eq (Resource s q) where
  x == y = resourceCountRef x == resourceCountRef y  -- unique references

-- | Create a new FCFS resource with the specified initial count which value becomes
-- the upper bound as well.
newFCFSResource :: Int
                   -- ^ the initial count (and maximal count too) of the resource
                   -> Simulation FCFSResource
newFCFSResource = newResource FCFS

-- | Create a new FCFS resource with the specified initial and maximum counts,
-- where 'Nothing' means that the resource has no upper bound.
newFCFSResourceWithMaxCount :: Int
                               -- ^ the initial count of the resource
                               -> Maybe Int
                               -- ^ the maximum count of the resource, which can be indefinite
                               -> Simulation FCFSResource
newFCFSResourceWithMaxCount = newResourceWithMaxCount FCFS

-- | Create a new LCFS resource with the specified initial count which value becomes
-- the upper bound as well.
newLCFSResource :: Int
                   -- ^ the initial count (and maximal count too) of the resource
                   -> Simulation LCFSResource
newLCFSResource = newResource LCFS

-- | Create a new LCFS resource with the specified initial and maximum counts,
-- where 'Nothing' means that the resource has no upper bound.
newLCFSResourceWithMaxCount :: Int
                               -- ^ the initial count of the resource
                               -> Maybe Int
                               -- ^ the maximum count of the resource, which can be indefinite
                               -> Simulation LCFSResource
newLCFSResourceWithMaxCount = newResourceWithMaxCount LCFS

-- | Create a new SIRO resource with the specified initial count which value becomes
-- the upper bound as well.
newSIROResource :: Int
                   -- ^ the initial count (and maximal count too) of the resource
                   -> Simulation SIROResource
newSIROResource = newResource SIRO

-- | Create a new SIRO resource with the specified initial and maximum counts,
-- where 'Nothing' means that the resource has no upper bound.
newSIROResourceWithMaxCount :: Int
                               -- ^ the initial count of the resource
                               -> Maybe Int
                               -- ^ the maximum count of the resource, which can be indefinite
                               -> Simulation SIROResource
newSIROResourceWithMaxCount = newResourceWithMaxCount SIRO

-- | Create a new priority resource with the specified initial count which value becomes
-- the upper bound as well.
newPriorityResource :: Int
                       -- ^ the initial count (and maximal count too) of the resource
                       -> Simulation PriorityResource
newPriorityResource = newResource StaticPriorities

-- | Create a new priority resource with the specified initial and maximum counts,
-- where 'Nothing' means that the resource has no upper bound.
newPriorityResourceWithMaxCount :: Int
                                   -- ^ the initial count of the resource
                                   -> Maybe Int
                                   -- ^ the maximum count of the resource, which can be indefinite
                                   -> Simulation PriorityResource
newPriorityResourceWithMaxCount = newResourceWithMaxCount StaticPriorities

-- | Create a new resource with the specified queue strategy and initial count.
-- The last value becomes the upper bound as well.
newResource :: QueueStrategy s q
               => s
               -- ^ the strategy for managing the queuing requests
               -> Int
               -- ^ the initial count (and maximal count too) of the resource
               -> Simulation (Resource s q)
newResource s count =
  Simulation $ \r ->
  do when (count < 0) $
       error $
       "The resource count cannot be negative: " ++
       "newResource."
     countRef <- newIORef count
     waitList <- invokeSimulation r $ newStrategyQueue s
     return Resource { resourceStrategy = s,
                       resourceMaxCount = Just count,
                       resourceCountRef = countRef,
                       resourceWaitList = waitList }

-- | Create a new resource with the specified queue strategy, initial and maximum counts,
-- where 'Nothing' means that the resource has no upper bound.
newResourceWithMaxCount :: QueueStrategy s q
                           => s
                           -- ^ the strategy for managing the queuing requests
                           -> Int
                           -- ^ the initial count of the resource
                           -> Maybe Int
                           -- ^ the maximum count of the resource, which can be indefinite
                           -> Simulation (Resource s q)
newResourceWithMaxCount s count maxCount =
  Simulation $ \r ->
  do when (count < 0) $
       error $
       "The resource count cannot be negative: " ++
       "newResourceWithMaxCount."
     case maxCount of
       Just maxCount | count > maxCount ->
         error $
         "The resource count cannot be greater than " ++
         "its maximum value: newResourceWithMaxCount."
       _ ->
         return ()
     countRef <- newIORef count
     waitList <- invokeSimulation r $ newStrategyQueue s
     return Resource { resourceStrategy = s,
                       resourceMaxCount = maxCount,
                       resourceCountRef = countRef,
                       resourceWaitList = waitList }

-- | Return the current count of the resource.
resourceCount :: Resource s q -> Event Int
resourceCount r =
  Event $ \p -> readIORef (resourceCountRef r)

-- | Request for the resource decreasing its count in case of success,
-- otherwise suspending the discontinuous process until some other 
-- process releases the resource.
requestResource :: EnqueueStrategy s q
                   => Resource s q
                   -- ^ the requested resource
                   -> Process ()
requestResource r =
  Process $ \pid ->
  Cont $ \c ->
  Event $ \p ->
  do a <- readIORef (resourceCountRef r)
     if a == 0 
       then invokeEvent p $
            strategyEnqueue (resourceStrategy r) (resourceWaitList r) c
       else do let a' = a - 1
               a' `seq` writeIORef (resourceCountRef r) a'
               invokeEvent p $ resumeCont c ()

-- | Request with the priority for the resource decreasing its count
-- in case of success, otherwise suspending the discontinuous process
-- until some other process releases the resource.
requestResourceWithPriority :: PriorityQueueStrategy s q p
                               => Resource s q
                               -- ^ the requested resource
                               -> p
                               -- ^ the priority
                               -> Process ()
requestResourceWithPriority r priority =
  Process $ \pid ->
  Cont $ \c ->
  Event $ \p ->
  do a <- readIORef (resourceCountRef r)
     if a == 0 
       then invokeEvent p $
            strategyEnqueueWithPriority (resourceStrategy r) (resourceWaitList r) priority c
       else do let a' = a - 1
               a' `seq` writeIORef (resourceCountRef r) a'
               invokeEvent p $ resumeCont c ()

-- | Release the resource increasing its count and resuming one of the
-- previously suspended processes as possible.
releaseResource :: DequeueStrategy s q
                   => Resource s q
                   -- ^ the resource to release
                   -> Process ()
releaseResource r = 
  Process $ \_ ->
  Cont $ \c ->
  Event $ \p ->
  do invokeEvent p $ releaseResourceWithinEvent r
     invokeEvent p $ resumeCont c ()

-- | Release the resource increasing its count and resuming one of the
-- previously suspended processes as possible.
releaseResourceWithinEvent :: DequeueStrategy s q
                              => Resource s q
                              -- ^ the resource to release
                              -> Event ()
releaseResourceWithinEvent r =
  Event $ \p ->
  do a <- readIORef (resourceCountRef r)
     let a' = a + 1
     case resourceMaxCount r of
       Just maxCount | a' > maxCount ->
         error $
         "The resource count cannot be greater than " ++
         "its maximum value: releaseResourceWithinEvent."
       _ ->
         return ()
     f <- invokeEvent p $
          strategyQueueNull (resourceStrategy r) (resourceWaitList r)
     if f 
       then a' `seq` writeIORef (resourceCountRef r) a'
       else do c <- invokeEvent p $
                    strategyDequeue (resourceStrategy r) (resourceWaitList r)
               invokeEvent p $ enqueueEvent (pointTime p) $
                 Event $ \p ->
                 do z <- contCanceled c
                    if z
                      then do invokeEvent p $ releaseResourceWithinEvent r
                              invokeEvent p $ resumeCont c ()
                      else invokeEvent p $ resumeCont c ()

-- | Try to request for the resource decreasing its count in case of success
-- and returning 'True' in the 'Event' monad; otherwise, returning 'False'.
tryRequestResourceWithinEvent :: Resource s q
                                 -- ^ the resource which we try to request for
                                 -> Event Bool
tryRequestResourceWithinEvent r =
  Event $ \p ->
  do a <- readIORef (resourceCountRef r)
     if a == 0 
       then return False
       else do let a' = a - 1
               a' `seq` writeIORef (resourceCountRef r) a'
               return True
               
-- | Acquire the resource, perform some action and safely release the resource               
-- in the end, even if the 'IOException' was raised within the action. 
-- The process identifier must be created with support of exception 
-- handling, i.e. with help of function 'newProcessIdWithCatch'. Unfortunately,
-- such processes are slower than those that are created with help of
-- other function 'newProcessId'.
usingResource :: EnqueueStrategy s q
                 => Resource s q
                 -- ^ the resource we are going to request for and then release in the end
                 -> Process a
                 -- ^ the action we are going to apply having the resource
                 -> Process a
                 -- ^ the result of the action
usingResource r m =
  do requestResource r
     finallyProcess m $ releaseResource r

-- | Acquire the resource with the specified priority, perform some action and
-- safely release the resource in the end, even if the 'IOException' was raised
-- within the action. The process identifier must be created with support of exception 
-- handling, i.e. with help of function 'newProcessIdWithCatch'. Unfortunately,
-- such processes are slower than those that are created with help of
-- other function 'newProcessId'.
usingResourceWithPriority :: PriorityQueueStrategy s q p
                             => Resource s q
                             -- ^ the resource we are going to request for and then
                             -- release in the end
                             -> p
                             -- ^ the priority
                             -> Process a
                             -- ^ the action we are going to apply having the resource
                             -> Process a
                             -- ^ the result of the action
usingResourceWithPriority r priority m =
  do requestResourceWithPriority r priority
     finallyProcess m $ releaseResource r
