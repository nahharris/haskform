import Test.Hspec
import Haskform.DSL.Core
import Haskform.DSL.SmartConstructors
import Haskform.DSL.Interpreters
import Haskform.Core.State
import Haskform.Core.Plan

main :: IO ()
main = hspec $ do
    describe "Haskform.DSL.Core" $ do
        it "mkResource creates a resource operation" $ do
            let res = mkResource (ResourceType "aws:ec2:instance") (ResourceConfig ())
            case res of
              Op (MkResourceOp rt _) _ -> rt `shouldBe` ResourceType "aws:ec2:instance"
              Pure _ -> expectationFailure "Expected Op"

        it "readState creates a read state operation" $ do
            let op = readState
            case op of
              Op ReadStateOp _ -> return ()
              Pure _ -> expectationFailure "Expected Op"

    describe "Haskform.DSL.Interpreters" $ do
        it "mockInterpreter runs a simple program" $ do
            let prog = do
                    r <- mkResource (ResourceType "test:resource") (ResourceConfig "config")
                    pure r
            case mockInterpreter prog of
              Right (MockState st, r) -> do
                resourceId r `shouldNotBe` ResourceId ""
                resourceType r `shouldBe` ResourceType "test:resource"
                length (stateResources st) `shouldBe` 1
              Left (IaCError msg) -> expectationFailure $ "Expected Right, got: " <> msg

        it "runIaC returns the result value" $ do
            let prog = do
                    r <- mkResource (ResourceType "test") (ResourceConfig ())
                    pure (resourceId r)
            case runIaC prog of
              Right rid -> rid `shouldNotBe` ResourceId ""
              Left (IaCError msg) -> expectationFailure $ "Expected Right, got: " <> msg

        it "mockInterpreter handles multiple resources" $ do
            let prog = do
                    r1 <- mkResource (ResourceType "vpc") (ResourceConfig "vpc1")
                    r2 <- mkResource (ResourceType "ec2") (ResourceConfig "ec2")
                    pure (r1, r2)
            case mockInterpreter prog of
              Right (MockState st, (res1, res2)) -> do
                resourceId res1 `shouldNotBe` resourceId res2
                length (stateResources st) `shouldBe` 2
              Left (IaCError msg) -> expectationFailure $ "Expected Right, got: " <> msg

    describe "Haskform.Core.Plan" $ do
        it "planInterpreter generates creates" $ do
            let prog = mkResource (ResourceType "vpc") (ResourceConfig "my-vpc")
            case planInterpreter emptyState prog of
              Right (pr, _r) -> do
                length (planCreates (prPlan pr)) `shouldBe` 1
                length (planUpdates (prPlan pr)) `shouldBe` 0
                length (planDeletes (prPlan pr)) `shouldBe` 0
              Left (IaCError msg) -> expectationFailure $ "Expected Right, got: " <> msg

        it "planInterpreter generates deletes" $ do
            let existingState = emptyState { stateResources = stateResources emptyState }
            let prog = deleteResource (ResourceId "test-id")
            case planInterpreter existingState prog of
              Right (pr, ()) -> do
                length (planDeletes (prPlan pr)) `shouldBe` 1
              Left (IaCError msg) -> expectationFailure $ "Expected Right, got: " <> msg