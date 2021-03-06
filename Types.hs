module Types where

import Control.Monad
import DynFlags
import Exception
import GHC
import GHC.Paths (libdir)

----------------------------------------------------------------

data Options = Options {
    convert   :: [String] -> String
  , hlintOpts :: [String]
  , operators :: Bool
  }

withGHC :: (MonadPlus m) => Ghc (m a) -> IO (m a)
withGHC body = ghandle ignore $ runGhc (Just libdir) body
  where
    ignore :: (MonadPlus m) => SomeException -> IO (m a)
    ignore _ = return mzero

----------------------------------------------------------------

initSession0 :: Ghc [PackageId]
initSession0 = getSessionDynFlags >>= setSessionDynFlags

initSession :: [String] -> Ghc [PackageId]
initSession cmdOpts = do
    dflags <- getSessionDynFlags
    let opts = map noLoc cmdOpts
    (dflags',_,_) <- parseDynamicFlags dflags opts
    setSessionDynFlags $ setFlags dflags'

----------------------------------------------------------------

setFlags :: DynFlags -> DynFlags
setFlags d = d {
    importPaths = importPaths d ++ importDirs
  , packageFlags = ghcPackage : packageFlags d
  , ghcLink = NoLink
-- GHC.desugarModule does not produces the pattern warnings, why?
--  , hscTarget = HscNothing
  , hscTarget = HscInterpreted
  }

importDirs :: [String]
importDirs = ["..","../..","../../..","../../../..","../../../../.."]

ghcPackage :: PackageFlag
ghcPackage = ExposePackage "ghc"

----------------------------------------------------------------

setTargetFile :: (GhcMonad m) => String -> m ()
setTargetFile file = do
    target <- guessTarget file Nothing
    setTargets [target]
