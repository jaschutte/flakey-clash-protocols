{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-missing-fields #-}
{-# OPTIONS_GHC -fconstraint-solver-iterations=10 #-}

{- |
Defines WriteAddress channel of full AXI4 protocol with port names corresponding
to the AXI4 specification.
-}
module Protocols.Axi4.WriteAddress (
  M2S_WriteAddress (..),
  S2M_WriteAddress (..),
  Axi4WriteAddress,

  -- * configuration
  Axi4WriteAddressConfig (..),
  KnownAxi4WriteAddressConfig,
  AWKeepBurst,
  AWKeepSize,
  AWIdWidth,
  AWAddrWidth,
  AWKeepRegion,
  AWKeepBurstLength,
  AWKeepLock,
  AWKeepCache,
  AWKeepPermissions,
  AWKeepQos,

  -- * write address info
  Axi4WriteAddressInfo (..),
  axi4WriteAddrMsgToWriteAddrInfo,
  axi4WriteAddrMsgFromWriteAddrInfo,
  forceResetSanity,
) where

-- base
import Control.DeepSeq (NFData)
import Data.Coerce (coerce)
import Data.Kind (Type)
import GHC.Generics (Generic)

-- clash-prelude
import Clash.Prelude qualified as C

-- me
import Protocols.Axi4.Common
import Protocols.Idle
import Protocols.Internal

-- | Configuration options for 'Axi4WriteAddress'.
data Axi4WriteAddressConfig = Axi4WriteAddressConfig
  { _awKeepBurst :: Bool
  , _awKeepSize :: Bool
  , _awIdWidth :: C.Nat
  , _awAddrWidth :: C.Nat
  , _awKeepRegion :: Bool
  , _awKeepBurstLength :: Bool
  , _awKeepLock :: Bool
  , _awKeepCache :: Bool
  , _awKeepPermissions :: Bool
  , _awKeepQos :: Bool
  }

{- | Grab '_awKeepBurst' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awburst' field
in 'M2S_WriteAddress'.
-}
type family AWKeepBurst (c :: Axi4WriteAddressConfig) where
  AWKeepBurst ('Axi4WriteAddressConfig a _ _ _ _ _ _ _ _ _) = a

{- | Grab '_awKeepSize' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awsize' field
in 'M2S_WriteAddress'.
-}
type family AWKeepSize (c :: Axi4WriteAddressConfig) where
  AWKeepSize ('Axi4WriteAddressConfig _ a _ _ _ _ _ _ _ _) = a

{- | Grab '_awIdWidth' from 'Axi4WriteAddressConfig' at the type level.
This nat value determines the size of the '_awid' field
in 'M2S_WriteAddress'.
-}
type family AWIdWidth (c :: Axi4WriteAddressConfig) where
  AWIdWidth ('Axi4WriteAddressConfig _ _ a _ _ _ _ _ _ _) = a

{- | Grab '_awAddrWidth' from 'Axi4WriteAddressConfig' at the type level.
This nat value determines the size of the '_awaddr' field
in 'M2S_WriteAddress'.
-}
type family AWAddrWidth (c :: Axi4WriteAddressConfig) where
  AWAddrWidth ('Axi4WriteAddressConfig _ _ _ a _ _ _ _ _ _) = a

{- | Grab '_awKeepRegion' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awregion' field
in 'M2S_WriteAddress'.
-}
type family AWKeepRegion (c :: Axi4WriteAddressConfig) where
  AWKeepRegion ('Axi4WriteAddressConfig _ _ _ _ a _ _ _ _ _) = a

{- | Grab '_awKeepBurstLength' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awlen' field
in 'M2S_WriteAddress'.
-}
type family AWKeepBurstLength (c :: Axi4WriteAddressConfig) where
  AWKeepBurstLength ('Axi4WriteAddressConfig _ _ _ _ _ a _ _ _ _) = a

{- | Grab '_awKeepLock' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awlock' field
in 'M2S_WriteAddress'.
-}
type family AWKeepLock (c :: Axi4WriteAddressConfig) where
  AWKeepLock ('Axi4WriteAddressConfig _ _ _ _ _ _ a _ _ _) = a

{- | Grab '_awKeepCache' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awcache' field
in 'M2S_WriteAddress'.
-}
type family AWKeepCache (c :: Axi4WriteAddressConfig) where
  AWKeepCache ('Axi4WriteAddressConfig _ _ _ _ _ _ _ a _ _) = a

{- | Grab '_awKeepPermissions' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awprot' field
in 'M2S_WriteAddress'.
-}
type family AWKeepPermissions (c :: Axi4WriteAddressConfig) where
  AWKeepPermissions ('Axi4WriteAddressConfig _ _ _ _ _ _ _ _ a _) = a

{- | Grab '_awKeepQos' from 'Axi4WriteAddressConfig' at the type level.
This boolean value determines whether to keep the '_awqos' field
in 'M2S_WriteAddress'.
-}
type family AWKeepQos (c :: Axi4WriteAddressConfig) where
  AWKeepQos ('Axi4WriteAddressConfig _ _ _ _ _ _ _ _ _ a) = a

-- | AXI4 Write Address channel protocol
data
  Axi4WriteAddress
    (dom :: C.Domain)
    (conf :: Axi4WriteAddressConfig)
    (userType :: Type)

instance Protocol (Axi4WriteAddress dom conf userType) where
  type
    Fwd (Axi4WriteAddress dom conf userType) =
      C.Signal dom (M2S_WriteAddress conf userType)
  type
    Bwd (Axi4WriteAddress dom conf userType) =
      C.Signal dom S2M_WriteAddress

instance Backpressure (Axi4WriteAddress dom conf userType) where
  boolsToBwd _ = C.fromList_lazy . coerce

-- | See Table A2-2 "Write address channel signals"
data
  M2S_WriteAddress
    (conf :: Axi4WriteAddressConfig)
    (userType :: Type)
  = M2S_NoWriteAddress
  | M2S_WriteAddress
      { _awid :: C.BitVector (AWIdWidth conf)
      -- ^ Write address id*
      , _awaddr :: C.BitVector (AWAddrWidth conf)
      -- ^ Write address
      , _awregion :: RegionType (AWKeepRegion conf)
      -- ^ Write region*
      , _awlen :: BurstLengthType (AWKeepBurstLength conf)
      -- ^ Burst length*
      , _awsize :: SizeType (AWKeepSize conf)
      -- ^ Burst size*
      , _awburst :: BurstType (AWKeepBurst conf)
      -- ^ Burst type*
      , _awlock :: LockType (AWKeepLock conf)
      -- ^ Lock type*
      , _awcache :: AwCacheType (AWKeepCache conf)
      -- ^ Cache type*
      , _awprot :: PermissionsType (AWKeepPermissions conf)
      -- ^ Protection type
      , _awqos :: QosType (AWKeepQos conf)
      -- ^ QoS value
      , _awuser :: userType
      -- ^ User data
      }
  deriving (Generic)

-- | See Table A2-2 "Write address channel signals"
newtype S2M_WriteAddress = S2M_WriteAddress {_awready :: Bool}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (C.ShowX, C.NFDataX, C.BitPack)

{- | Shorthand for a "well-behaved" write address config,
so that we don't need to write out a bunch of type constraints later.
Holds for every configuration; don't worry about implementing this class.
-}
type KnownAxi4WriteAddressConfig conf =
  ( KeepTypeClass (AWKeepBurst conf)
  , KeepTypeClass (AWKeepSize conf)
  , KeepTypeClass (AWKeepRegion conf)
  , KeepTypeClass (AWKeepBurstLength conf)
  , KeepTypeClass (AWKeepLock conf)
  , KeepTypeClass (AWKeepCache conf)
  , KeepTypeClass (AWKeepPermissions conf)
  , KeepTypeClass (AWKeepQos conf)
  , C.KnownNat (AWIdWidth conf)
  , C.KnownNat (AWAddrWidth conf)
  , C.ShowX (RegionType (AWKeepRegion conf))
  , C.ShowX (BurstLengthType (AWKeepBurstLength conf))
  , C.ShowX (SizeType (AWKeepSize conf))
  , C.ShowX (BurstType (AWKeepBurst conf))
  , C.ShowX (LockType (AWKeepLock conf))
  , C.ShowX (AwCacheType (AWKeepCache conf))
  , C.ShowX (PermissionsType (AWKeepPermissions conf))
  , C.ShowX (QosType (AWKeepQos conf))
  , Show (RegionType (AWKeepRegion conf))
  , Show (BurstLengthType (AWKeepBurstLength conf))
  , Show (SizeType (AWKeepSize conf))
  , Show (BurstType (AWKeepBurst conf))
  , Show (LockType (AWKeepLock conf))
  , Show (AwCacheType (AWKeepCache conf))
  , Show (PermissionsType (AWKeepPermissions conf))
  , Show (QosType (AWKeepQos conf))
  , C.NFDataX (RegionType (AWKeepRegion conf))
  , C.NFDataX (BurstLengthType (AWKeepBurstLength conf))
  , C.NFDataX (SizeType (AWKeepSize conf))
  , C.NFDataX (BurstType (AWKeepBurst conf))
  , C.NFDataX (LockType (AWKeepLock conf))
  , C.NFDataX (AwCacheType (AWKeepCache conf))
  , C.NFDataX (PermissionsType (AWKeepPermissions conf))
  , C.NFDataX (QosType (AWKeepQos conf))
  , C.BitPack (RegionType (AWKeepRegion conf))
  , C.BitPack (BurstLengthType (AWKeepBurstLength conf))
  , C.BitPack (SizeType (AWKeepSize conf))
  , C.BitPack (BurstType (AWKeepBurst conf))
  , C.BitPack (LockType (AWKeepLock conf))
  , C.BitPack (AwCacheType (AWKeepCache conf))
  , C.BitPack (PermissionsType (AWKeepPermissions conf))
  , C.BitPack (QosType (AWKeepQos conf))
  , NFData (RegionType (AWKeepRegion conf))
  , NFData (BurstLengthType (AWKeepBurstLength conf))
  , NFData (SizeType (AWKeepSize conf))
  , NFData (BurstType (AWKeepBurst conf))
  , NFData (LockType (AWKeepLock conf))
  , NFData (AwCacheType (AWKeepCache conf))
  , NFData (PermissionsType (AWKeepPermissions conf))
  , NFData (QosType (AWKeepQos conf))
  , Eq (RegionType (AWKeepRegion conf))
  , Eq (BurstLengthType (AWKeepBurstLength conf))
  , Eq (SizeType (AWKeepSize conf))
  , Eq (BurstType (AWKeepBurst conf))
  , Eq (LockType (AWKeepLock conf))
  , Eq (AwCacheType (AWKeepCache conf))
  , Eq (PermissionsType (AWKeepPermissions conf))
  , Eq (QosType (AWKeepQos conf))
  )

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , Show userType
  ) =>
  Show (M2S_WriteAddress conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , C.ShowX userType
  ) =>
  C.ShowX (M2S_WriteAddress conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , C.NFDataX userType
  ) =>
  C.NFDataX (M2S_WriteAddress conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , Eq userType
  ) =>
  Eq (M2S_WriteAddress conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , C.BitPack userType
  ) =>
  C.BitPack (M2S_WriteAddress conf userType)

{- | Mainly for use in @DfConv@.

Data carried along 'Axi4WriteAddress' channel which is put in control of
the user, rather than being managed by the @DfConv@ instances. Matches up
one-to-one with the fields of 'M2S_WriteAddress' except for '_awlen',
'_awsize', and '_awburst'.
-}
data Axi4WriteAddressInfo (conf :: Axi4WriteAddressConfig) (userType :: Type) = Axi4WriteAddressInfo
  { _awiid :: C.BitVector (AWIdWidth conf)
  -- ^ Id
  , _awiaddr :: C.BitVector (AWAddrWidth conf)
  -- ^ Address
  , _awiregion :: RegionType (AWKeepRegion conf)
  -- ^ Region
  , _awisize :: SizeType (AWKeepSize conf)
  -- ^ Burst size
  , _awilock :: LockType (AWKeepLock conf)
  -- ^ Lock type
  , _awicache :: AwCacheType (AWKeepCache conf)
  -- ^ Cache type
  , _awiprot :: PermissionsType (AWKeepPermissions conf)
  -- ^ Protection type
  , _awiqos :: QosType (AWKeepQos conf)
  -- ^ QoS value
  , _awiuser :: userType
  -- ^ User data
  }
  deriving (Generic)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , Show userType
  ) =>
  Show (Axi4WriteAddressInfo conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , C.ShowX userType
  ) =>
  C.ShowX (Axi4WriteAddressInfo conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , C.NFDataX userType
  ) =>
  C.NFDataX (Axi4WriteAddressInfo conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , NFData userType
  ) =>
  NFData (Axi4WriteAddressInfo conf userType)

deriving instance
  ( KnownAxi4WriteAddressConfig conf
  , Eq userType
  ) =>
  Eq (Axi4WriteAddressInfo conf userType)

-- | Convert 'M2S_WriteAddress' to 'Axi4WriteAddressInfo', dropping some info
axi4WriteAddrMsgToWriteAddrInfo ::
  M2S_WriteAddress conf userType ->
  Axi4WriteAddressInfo conf userType
axi4WriteAddrMsgToWriteAddrInfo M2S_NoWriteAddress = C.errorX "Expected WriteAddress"
axi4WriteAddrMsgToWriteAddrInfo M2S_WriteAddress{..} =
  Axi4WriteAddressInfo
    { _awiid = _awid
    , _awiaddr = _awaddr
    , _awiregion = _awregion
    , _awisize = _awsize
    , _awilock = _awlock
    , _awicache = _awcache
    , _awiprot = _awprot
    , _awiqos = _awqos
    , _awiuser = _awuser
    }

-- | Convert 'Axi4WriteAddressInfo' to 'M2S_WriteAddress', adding some info
axi4WriteAddrMsgFromWriteAddrInfo ::
  BurstLengthType (AWKeepBurstLength conf) ->
  BurstType (AWKeepBurst conf) ->
  Axi4WriteAddressInfo conf userType ->
  M2S_WriteAddress conf userType
axi4WriteAddrMsgFromWriteAddrInfo _awlen _awburst Axi4WriteAddressInfo{..} =
  M2S_WriteAddress
    { _awid = _awiid
    , _awaddr = _awiaddr
    , _awregion = _awiregion
    , _awsize = _awisize
    , _awlock = _awilock
    , _awcache = _awicache
    , _awprot = _awiprot
    , _awqos = _awiqos
    , _awuser = _awiuser
    , _awlen
    , _awburst
    }

instance IdleCircuit (Axi4WriteAddress dom conf userType) where
  idleFwd _ = C.pure M2S_NoWriteAddress
  idleBwd _ = C.pure $ S2M_WriteAddress False

{- | Force a /nack/ on the backward channel and /no data/ on the forward
channel if reset is asserted.
-}
forceResetSanity ::
  (C.KnownDomain dom, C.HiddenReset dom) =>
  Circuit (Axi4WriteAddress dom conf userType) (Axi4WriteAddress dom conf userType)
forceResetSanity = forceResetSanityGeneric
