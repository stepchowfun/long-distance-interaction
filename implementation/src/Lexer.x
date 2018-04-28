{

{-# OPTIONS_GHC -Wwarn=unused-imports #-}

module Lexer (Token(..), scan) where

}

%wrapper "monad"

$digit = 0-9
$alpha = [a-zA-Z]
@identifier = $alpha [$alpha $digit _]*

:-

$white+     ;
"#".*       ;
"("         { tokenAtom TokenLParen }
")"         { tokenAtom TokenRParen }
"+"         { tokenAtom TokenPlus }
"->"        { tokenAtom TokenArrow }
"."         { tokenAtom TokenDot }
":"         { tokenAtom TokenAnno }
"="         { tokenAtom TokenEquals }
"\"         { tokenAtom TokenLambda }
"forall"    { tokenAtom TokenForAll }
"in"        { tokenAtom TokenIn }
"let"       { tokenAtom TokenLet }
$digit+     { tokenInteger TokenIntLit }
@identifier { tokenString TokenId }

{

data Token
  = TokenAnno
  | TokenArrow
  | TokenDot
  | TokenEquals
  | TokenForAll
  | TokenId String
  | TokenIn
  | TokenIntLit Integer
  | TokenLParen
  | TokenLambda
  | TokenLet
  | TokenPlus
  | TokenRParen
  deriving Eq

instance Show Token where
  show (TokenId x) = x
  show (TokenIntLit x) = show x
  show TokenAnno = ":"
  show TokenArrow = "->"
  show TokenDot = "."
  show TokenEquals = "="
  show TokenForAll = "forall"
  show TokenIn = "in"
  show TokenLParen = "("
  show TokenLambda = "\\"
  show TokenLet = "let"
  show TokenPlus = "+"
  show TokenRParen = ")"

alexScanAction :: Alex (Maybe Token)
alexScanAction = do
  input <- alexGetInput
  sc <- alexGetStartCode
  case alexScan input sc of
    AlexEOF -> alexEOF
    AlexError _ -> alexError $ "Lexical error."
    AlexSkip  newInp _ -> do
        alexSetInput newInp
        alexScanAction
    AlexToken newInp len action -> do
        alexSetInput newInp
        action (ignorePendingBytes input) len

scan :: String -> Either String [Token]
scan s = fmap reverse $ runAlex s $ do
  let loop memo = do r <- alexScanAction
                     case r of
                       Nothing -> return memo
                       Just t -> do rest <- loop (t : memo)
                                    return rest
  loop []

alexEOF :: Alex (Maybe Token)
alexEOF = return Nothing

tokenAtom :: Token -> AlexAction (Maybe Token)
tokenAtom t = token (\_ _ -> Just t)

tokenString :: (String -> Token) -> AlexAction (Maybe Token)
tokenString t = token (\(_, _, _, s) len -> Just $ t (take len s))

tokenInteger :: (Integer -> Token) -> AlexAction (Maybe Token)
tokenInteger t = token (\(_, _, _, s) len -> Just $ t (read (take len s) :: Integer))

}
