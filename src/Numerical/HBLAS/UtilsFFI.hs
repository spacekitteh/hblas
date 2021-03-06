{-# LANGUAGE Trustworthy #-}
{- VERY TRUST WORTHY :) -}
module Numerical.HBLAS.UtilsFFI where



import   Data.Vector.Storable.Mutable  as  M 
import Control.Monad.Primitive
import Foreign.ForeignPtr.Safe
import Foreign.ForeignPtr.Unsafe

import Foreign.Storable.Complex
import Data.Vector.Storable as S 
import Foreign.Ptr

{-
the IO version of these various utils is in Base.
but would like to have the 
-}

withRWStorable:: (Storable a, PrimMonad m)=> a -> (Ptr a -> m b) -> m a 
withRWStorable val fun = do 
    valVect <- M.replicate 1 val 
    _ <- unsafeWithPrim valVect fun 
    M.unsafeRead valVect 0 
{-# INLINE withRWStorable #-}    


withRStorable :: (Storable a, PrimMonad m)=> a -> (Ptr a -> m b) -> m b 
withRStorable val fun = do   
    valVect <- M.replicate 1 val 
    unsafeWithPrim valVect fun 
{-# INLINE withRStorable #-} 

withRStorable_ :: (Storable a, PrimMonad m)=> a -> (Ptr a -> m ()) -> m ()
withRStorable_ val fun = do   
    valVect <- M.replicate 1 val 
    unsafeWithPrim valVect fun 

    return () 
{-# INLINE withRStorable_ #-} 

withForeignPtrPrim :: PrimMonad m => ForeignPtr a -> (Ptr a -> m b) -> m b
withForeignPtrPrim  fo act
  = do r <- act (unsafeForeignPtrToPtr fo)
       touchForeignPtrPrim fo
       return r
{-# INLINE withForeignPtrPrim #-}       

touchForeignPtrPrim ::PrimMonad m => ForeignPtr a -> m ()
touchForeignPtrPrim fp = unsafePrimToPrim $!  touchForeignPtr fp
{-# NOINLINE touchForeignPtrPrim #-}


unsafeWithPrim ::( Storable a, PrimMonad m )=> MVector (PrimState m) a -> (Ptr a -> m b) -> m b
{-# INLINE unsafeWithPrim #-}
unsafeWithPrim (MVector _ fp)  fun = withForeignPtrPrim fp fun


unsafeWithPrimLen  ::( Storable a, PrimMonad m )=> MVector (PrimState m) a -> ((Ptr a, Int )-> m b) -> m b
{-# INLINE unsafeWithPrimLen #-}
unsafeWithPrimLen (MVector n fp ) fun =  withForeignPtrPrim fp (\x -> fun (x,n))


unsafeWithPurePrim  ::( Storable a, PrimMonad m )=> Vector a -> ((Ptr a)-> m b) -> m b
{-# INLINE unsafeWithPurePrim #-}
unsafeWithPurePrim v fun =   case S.unsafeToForeignPtr0 v of 
                    (fp,_) -> do 
                        res <-  withForeignPtrPrim fp (\x -> fun x)
                        touchForeignPtrPrim fp 
                        return res 

unsafeWithPurePrimLen  ::( Storable a, PrimMonad m )=> Vector a -> ((Ptr a, Int )-> m b) -> m b
{-# INLINE unsafeWithPurePrimLen #-}
unsafeWithPurePrimLen v fun =   case S.unsafeToForeignPtr0 v of 
                    (fp,n) -> do 
                        res <-  withForeignPtrPrim fp (\x -> fun (x,n))
                        touchForeignPtrPrim fp 
                        return res 

