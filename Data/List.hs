-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module Data.List(
  module Data.List_Type,
  (++), head, last, tail, init, uncons, unsnoc, singleton, null, length,
  map, reverse, intersperse, intercalate, transpose, subsequences, permutations,
  foldl, foldl', foldl1, foldl1', foldr, foldr', foldr1, foldr1',
  concat, concatMap, and, or, any, all, sum, product, maximum, minimum,
  scanl, scanl', scanl1, scanr, scanr1,
  mapAccumL, mapAccumR,
  iterate, iterate', repeat, replicate, cycle,
  unfoldr,
  take, drop, splitAt, takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, span, spanUntil, break, splitWith,
  spanEnd, breakEnd,
  stripPrefix, stripSuffix, group, inits, tails,
  isPrefixOf, isSuffixOf, isInfixOf, isSubsequenceOf,
  elem, notElem, lookup,
  find, filter, partition,
  (!?), (!!), elemIndex, elemIndices, findIndex, findIndices,
  zip, zip3, zip4, zip5, zip6, zip7,
  zipWith, zipWith3, zipWith4, zipWith5, zipWith6, zipWith7,
  unzip, unzip3, unzip4, unzip5, unzip6, unzip7,
  lines, words, unlines, unwords,
  nub, delete, (\\), union, intersect,
  sort, sortOn, insert,
  nubBy, deleteBy, deleteFirstsBy, unionBy, intersectBy, groupBy,
  sortBy, insertBy, maximumBy, minimumBy,
  genericLength, genericTake, genericDrop, genericSplitAt, genericIndex, genericReplicate,
  ) where
import Prelude()              -- do not import Prelude
import Primitives
import Control.Applicative
import Control.Error
import Data.Bool
import Data.Char
import Data.Eq
import Data.Function
import Data.Functor hiding(unzip)
import Data.Int
import Data.Integral
import Data.List_Type
import Data.Maybe_Type
import Data.Monoid.Internal
import Data.Num
import Data.Ord
import Data.Tuple
--import Text.Read
import Text.Show

instance {-# OVERLAPPABLE #-} forall a . Eq a => Eq [a] where
  []     == []      =  True
  (x:xs) == (y:ys)  =  x == y && xs == ys
  _      == _       =  False

instance forall a . Ord a => Ord [a] where
  []     <= _       =  True
  (_:_)  <= []      =  False
  (x:xs) <= (y:ys)  =  x < y || x == y && xs <= ys

instance Functor [] where
  fmap = map

instance Applicative [] where
  pure a = [a]
  fs <*> xs = concatMap (\ f -> map (\ x -> f x) xs) fs

instance forall a . Show a => Show [a] where
  showsPrec _ = showList

instance Alternative [] where
  empty = []
  (<|>) = (++)

instance forall a . Semigroup [a] where
  (<>) = (++)

instance forall a . Monoid [a] where
  mempty = []
  mconcat = concat

null :: forall a . [a] -> Bool
null [] = True
null _  = False

concat :: forall a . [[a]] -> [a]
concat = foldr (++) []

map :: forall a b . (a -> b) -> [a] -> [b]
map f =
  let
    rec [] = []
    rec (a : as) = f a : rec as
  in rec

filter :: forall a . (a -> Bool) -> [a] -> [a]
filter p =
  let
    rec [] = []
    rec (x : xs) = if p x then x : rec xs else rec xs
  in rec

foldr :: forall a b . (a -> b -> b) -> b -> [a] -> b
foldr f z =
  let
    rec [] = z
    rec (x : xs) = f x (rec xs)
  in rec

foldr' :: forall a b . (a -> b -> b) -> b -> [a] -> b
foldr' f z [] = z
foldr' f z (x:xs) =
  let y = foldr f z xs
  in  y `seq` f x y

foldr1 :: forall a . (a -> a -> a) -> [a] -> a
foldr1 f =
  let
    rec [] = error "foldr1"
    rec [x] = x
    rec (x : xs) = f x (rec xs)
  in rec

foldr1' :: forall a . (a -> a -> a) -> [a] -> a
foldr1' f =
  let
    rec [] = error "foldr1"
    rec [x] = x
    rec (x : xs) =
          let y = rec xs
          in  y `seq` f x y
  in rec

foldl :: forall a b . (b -> a -> b) -> b -> [a] -> b
foldl _ z [] = z
foldl f z (x : xs) = foldl f (f z x) xs

foldl' :: forall a b . (b -> a -> b) -> b -> [a] -> b
foldl' _ z [] = z
foldl' f z (x : xs) =
  let y = f z x
  in  y `seq` foldl f y xs

foldl1 :: forall a . (a -> a -> a) -> [a] -> a
foldl1 _ [] = error "foldl1"
foldl1 f (x : xs) = foldl f x xs

foldl1' :: forall a . (a -> a -> a) -> [a] -> a
foldl1' _ [] = error "foldl1'"
foldl1' f (x : xs) = foldl' f x xs

minimum :: forall a . Ord a => [a] -> a
minimum [] = error "minimum"
minimum (x:ys) = foldr (\ y m -> if y < m then y else m) x ys

maximum :: forall a . Ord a => [a] -> a
maximum [] = error "maximum"
maximum (x:ys) = foldr (\ y m -> if y > m then y else m) x ys

sum :: forall a . Num a => [a] -> a
sum = foldr (+) 0

product :: forall a . Num a => [a] -> a
product = foldr (*) 1

and :: [Bool] -> Bool
and = foldr (&&) True

or :: [Bool] -> Bool
or = foldr (||) False

any :: forall a . (a -> Bool) -> [a] -> Bool
any p = or . map p

all :: forall a . (a -> Bool) -> [a] -> Bool
all p = and . map p

take :: forall a . Int -> [a] -> [a]
take n arg =
  if n <= (0::Int) then
    []
  else
    case arg of
      [] -> []
      x : xs -> x : take (n - (1::Int)) xs

drop :: forall a . Int -> [a] -> [a]
drop n arg =
  if n <= (0::Int) then
    arg
  else
    case arg of
      [] -> []
      _ : xs -> drop (n - (1::Int)) xs

length :: forall a . [a] -> Int
length =
  -- Make it tail recursive and strict
  let
    rec r [] = r
    rec r (_:xs) =
          let r' = r + (1::Int)
          in  r' `primSeq` rec r' xs
  in rec (0::Int)

zip :: forall a b . [a] -> [b] -> [(a, b)]
zip = zipWith (\ x y -> (x, y))

zip3 :: forall a b c . [a] -> [b] -> [c] -> [(a, b, c)]
zip3 = zipWith3 (\ x y z -> (x, y, z))

zip4 :: forall a b c d . [a] -> [b] -> [c] -> [d] -> [(a, b, c, d)]
zip4 = zipWith4 (\ x y z w -> (x, y, z, w))

zip5 :: forall a b c d e . [a] -> [b] -> [c] -> [d] -> [e] -> [(a, b, c, d, e)]
zip5 = zipWith5 (\ x y z w u -> (x, y, z, w, u))

zip6 :: forall a b c d e f . [a] -> [b] -> [c] -> [d] -> [e] -> [f] -> [(a, b, c, d, e, f)]
zip6 = zipWith6 (\ x y z w u v -> (x, y, z, w, u, v))

zip7 :: forall a b c d e f g . [a] -> [b] -> [c] -> [d] -> [e] -> [f] -> [g] -> [(a, b, c, d, e, f, g)]
zip7 = zipWith7 (\ x y z w u v t -> (x, y, z, w, u, v, t))

zipWith :: forall a b r . (a -> b -> r) -> [a] -> [b] -> [r]
zipWith f (x:xs) (y:ys) = f x y : zipWith f xs ys
zipWith _ _ _ = []

zipWith3 :: forall a b c r . (a -> b -> c -> r) -> [a] -> [b] -> [c] -> [r]
zipWith3 f (x:xs) (y:ys) (z:zs) = f x y z : zipWith3 f xs ys zs
zipWith3 _ _ _ _ = []

zipWith4 :: forall a b c d r . (a -> b -> c -> d -> r) -> [a] -> [b] -> [c] -> [d] -> [r]
zipWith4 f (x:xs) (y:ys) (z:zs) (w:ws) = f x y z w : zipWith4 f xs ys zs ws
zipWith4 _ _ _ _ _ = []

zipWith5 :: forall a b c d e r . (a -> b -> c -> d -> e -> r) -> [a] -> [b] -> [c] -> [d] -> [e] -> [r]
zipWith5 f (x:xs) (y:ys) (z:zs) (w:ws) (u:us) = f x y z w u : zipWith5 f xs ys zs ws us
zipWith5 _ _ _ _ _ _ = []

zipWith6 :: forall a b c d e f r . (a -> b -> c -> d -> e -> f -> r) -> [a] -> [b] -> [c] -> [d] -> [e] -> [f] -> [r]
zipWith6 f (x:xs) (y:ys) (z:zs) (w:ws) (u:us) (v:vs) = f x y z w u v : zipWith6 f xs ys zs ws us vs
zipWith6 _ _ _ _ _ _ _ = []

zipWith7 :: forall a b c d e f g r . (a -> b -> c -> d -> e -> f -> g -> r) -> [a] -> [b] -> [c] -> [d] -> [e] -> [f] -> [g] -> [r]
zipWith7 f (x:xs) (y:ys) (z:zs) (w:ws) (u:us) (v:vs) (t:ts) = f x y z w u v t : zipWith7 f xs ys zs ws us vs ts
zipWith7 _ _ _ _ _ _ _ _ = []

-- XXX not as lazy as it could be
unzip :: forall a b . [(a, b)] -> ([a], [b])
unzip xys = (map fst xys, map snd xys)  -- this version is slightly faster than the other two
{-
unzip axys =
  case axys of
    [] -> ([], [])
    (x,y) : xys ->
      case unzip xys of
        (xs, ys) -> (x:xs, y:ys)
-}
{-
unzip [] = ([], [])
unzip ((x,y) : xys) =
  let (xs, ys) = unzip xys
  in  (x:xs, y:ys)
-}

-- XXX not as lazy as it could be
unzip3 :: forall a b c . [(a, b, c)] -> ([a], [b], [c])
unzip3 axyzs =
  case axyzs of
    [] -> ([], [], [])
    (x, y, z) : xyzs ->
      case unzip3 xyzs of
        (xs, ys, zs) -> (x:xs, y:ys, z:zs)

unzip4 :: forall a b c d . [(a, b, c, d)] -> ([a], [b], [c], [d])
unzip4 axyzs =
  case axyzs of
    [] -> ([], [], [], [])
    (x, y, z, w) : xyzs ->
      case unzip4 xyzs of
        (xs, ys, zs, ws) -> (x:xs, y:ys, z:zs, w:ws)

unzip5 :: forall a b c d e . [(a, b, c, d, e)] -> ([a], [b], [c], [d], [e])
unzip5 axyzs =
  case axyzs of
    [] -> ([], [], [], [], [])
    (x, y, z, w, v) : xyzs ->
      case unzip5 xyzs of
        (xs, ys, zs, ws, vs) -> (x:xs, y:ys, z:zs, w:ws, v:vs)

unzip6 :: forall a b c d e f . [(a, b, c, d, e, f)] -> ([a], [b], [c], [d], [e], [f])
unzip6 axyzs =
  case axyzs of
    [] -> ([], [], [], [], [], [])
    (x, y, z, w, v, u) : xyzs ->
      case unzip6 xyzs of
        (xs, ys, zs, ws, vs, us) -> (x:xs, y:ys, z:zs, w:ws, v:vs, u:us)

unzip7 :: forall a b c d e f g . [(a, b, c, d, e, f, g)] -> ([a], [b], [c], [d], [e], [f], [g])
unzip7 axyzs =
  case axyzs of
    [] -> ([], [], [], [], [], [], [])
    (x, y, z, w, v, u, t) : xyzs ->
      case unzip7 xyzs of
        (xs, ys, zs, ws, vs, us, ts) -> (x:xs, y:ys, z:zs, w:ws, v:vs, u:us, t:ts)

stripPrefix :: forall a . Eq a => [a] -> [a] -> Maybe [a]
stripPrefix = stripPrefixBy (==)

stripPrefixBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> Maybe [a]
stripPrefixBy eq [] s = Just s
stripPrefixBy eq (c:cs) [] = Nothing
stripPrefixBy eq (c:cs) (d:ds) | eq c d = stripPrefixBy eq cs ds
                               | otherwise = Nothing

stripSuffix :: forall a . Eq a => [a] -> [a] -> Maybe [a]
stripSuffix s t =
  case stripPrefix (reverse s) (reverse t) of
    Nothing -> Nothing
    Just x -> Just (reverse x)

isPrefixOf :: forall a . Eq a => [a] -> [a] -> Bool
isPrefixOf = isPrefixOfBy (==)

isPrefixOfBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> Bool
isPrefixOfBy eq (c:cs) (d:ds) = eq c d && isPrefixOfBy eq cs ds
isPrefixOfBy _ [] _ = True
isPrefixOfBy _ _  _ = False

isSuffixOf :: forall a . Eq a => [a] -> [a] -> Bool
isSuffixOf = isSuffixOfBy (==)

isSuffixOfBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> Bool
isSuffixOfBy eq n h = isPrefixOfBy eq (reverse n) (reverse h)

isInfixOf :: forall a . Eq a => [a] -> [a] -> Bool
isInfixOf = isInfixOfBy (==)

isInfixOfBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> Bool
isInfixOfBy eq cs ds = any (isPrefixOfBy eq cs) (inits ds)

splitAt :: forall a . Int -> [a] -> ([a], [a])
splitAt n xs = (take n xs, drop n xs)

reverse :: forall a . [a] -> [a]
reverse =
  let
    rev r [] = r
    rev r (x:xs) = rev (x:r) xs
  in  rev []

takeWhile :: forall a . (a -> Bool) -> [a] -> [a]
takeWhile _ [] = []
takeWhile p (x:xs) =
  if p x then
    x : takeWhile p xs
  else
    []

takeWhileEnd :: forall a . (a -> Bool) -> [a] -> [a]
takeWhileEnd p = reverse . takeWhile p . reverse

dropWhile :: forall a . (a -> Bool) -> [a] -> [a]
dropWhile _ [] = []
dropWhile p (x:xs) =
  if p x then
    dropWhile p xs
  else
    x : xs

dropWhileEnd :: (a -> Bool) -> [a] -> [a]
dropWhileEnd p = foldr (\x xs -> if p x && null xs then [] else x : xs) []

span :: forall a . (a -> Bool) -> [a] -> ([a], [a])
span p =
  let
    rec r [] = (reverse r, [])
    rec r (x:xs) = if p x then rec (x:r) xs else (reverse r, x:xs)
  in rec []

break :: forall a . (a -> Bool) -> [a] -> ([a],[a])
break p = span (not . p)

spanEnd :: (a -> Bool) -> [a] -> ([a], [a])
spanEnd p xs = (dropWhileEnd p xs, takeWhileEnd p xs)

breakEnd :: (a -> Bool) -> [a] -> ([a], [a])
breakEnd p = spanEnd (not . p)

spanUntil :: forall a . (a -> Bool) -> [a] -> ([a], [a])
spanUntil p =
  let
    rec r [] = (reverse r, [])
    rec r (x:xs) = if p x then rec (x:r) xs else (reverse (x:r), xs)
  in rec []

splitWith :: forall a . (a -> Bool) -> [a] -> [[a]]
splitWith p =
  let
    rec r s  []                = reverse (reverse s : r)
    rec r s (x:xs) | p x       = rec (reverse s : r) []      xs
                   | otherwise = rec              r  (x : s) xs
  in rec [] []

head :: forall a . [a] -> a
head [] = error "head"
head (x:_) = x

tail :: forall a . [a] -> [a]
tail [] = error "tail"
tail (_:ys) = ys

tails :: forall a . [a] -> [[a]]
tails [] = [[]]
tails xxs@(_:xs) = xxs : tails xs

inits :: forall a . [a] -> [[a]]
inits = map reverse . reverse . tails . reverse

intersperse :: forall a . a -> [a] -> [a]
intersperse _ [] = []
intersperse sep (a:as) = a : prepend as
  where
    prepend [] = []
    prepend (x:xs) = sep : x : prepend xs

intercalate :: forall a . [a] -> [[a]] -> [a]
intercalate xs xss = concat (intersperse xs xss)

elem :: forall a . (Eq a) => a -> [a] -> Bool
elem = elemBy (==)

elemBy :: (a -> a -> Bool) -> a -> [a] -> Bool
elemBy eq a = any (eq a)

notElem :: forall a . (Eq a) => a -> [a] -> Bool
notElem a as = not (elem a as)

find :: forall a . (a -> Bool) -> [a] -> Maybe a
find p [] = Nothing
find p (x:xs) = if p x then Just x else find p xs

lookup :: forall a b . Eq a => a -> [(a, b)] -> Maybe b
lookup = lookupBy (==)

lookupBy :: forall a b . (a -> a -> Bool) -> a -> [(a, b)] -> Maybe b
lookupBy eq x xys =
  case find (eq x . fst) xys of
    Nothing -> Nothing
    Just (_, b) -> Just b

union :: forall a . Eq a => [a] -> [a] -> [a]
union = unionBy (==)

unionBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> [a]
unionBy eq xs ys =  xs ++ foldl (flip (deleteBy eq)) (nubBy eq ys) xs

intersect :: forall a . Eq a => [a] -> [a] -> [a]
intersect = intersectBy (==)

intersectBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> [a]
intersectBy eq xs ys = filter (\ x -> elemBy eq x ys) xs

delete :: (Eq a) => a -> [a] -> [a]
delete = deleteBy (==)

deleteBy :: forall a . (a -> a -> Bool) -> a -> [a] -> [a]
deleteBy _ _ [] = []
deleteBy eq x (y:ys) = if eq x y then ys else y : deleteBy eq x ys

{-
deleteAllBy :: forall a . (a -> a -> Bool) -> a -> [a] -> [a]
deleteAllBy eq x = filter (not . eq x)
-}

nub :: forall a . Eq a => [a] -> [a]
nub = nubBy (==)

nubBy :: forall a . (a -> a -> Bool) -> [a] -> [a]
nubBy _ [] = []
nubBy eq (x:xs) = x : nubBy eq (filter (\ y -> not (eq x y)) xs)

replicate :: forall a . Int -> a -> [a]
replicate n x = take n (repeat x)

repeat :: forall a . a -> [a]
repeat x = let xs = x:xs in xs

cycle :: [a] -> [a]
cycle [] = error "cycle: []"
cycle xs = let xs' = xs ++ xs' in xs'

infix 5 \\
(\\) :: forall a . Eq a => [a] -> [a] -> [a]
(\\) = deleteFirstsBy (==)

deleteFirstsBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> [a]
deleteFirstsBy eq = foldl (flip (deleteBy eq))

{-
-- Delete all from the second argument from the first argument
deleteAllsBy :: forall a . (a -> a -> Bool) -> [a] -> [a] -> [a]
deleteAllsBy eq = foldl (flip (deleteAllBy eq))
-}

infixl 9 !!
(!!) :: forall a . [a] -> Int -> a
(!!) axs i =
  if i < (0::Int) then
    error "!!: <0"
  else
    let
      nth _ [] = error "!!: empty"
      nth n (x:xs) = if n == (0::Int) then x else nth (n - (1::Int)) xs
    in nth i axs

infixl 9 !?
(!?) :: forall a . [a] -> Int -> Maybe a
(!?) axs i =
  if i < (0::Int) then
    Nothing
  else
    let
      nth _ [] = Nothing
      nth n (x:xs) = if n == (0::Int) then Just x else nth (n - (1::Int)) xs
    in nth i axs

partition :: forall a . (a -> Bool) -> [a] -> ([a], [a])
partition p xs = (filter p xs, filter (not . p) xs)

sort :: forall a . Ord a => [a] -> [a]
sort = sortLE (<=)

sortBy :: forall a . (a -> a -> Ordering) -> [a] -> [a]
sortBy f = sortLE (\ x y -> f x y /= GT)

-- A simple "quicksort" for now.
sortLE :: forall a . (a -> a -> Bool) -> [a] -> [a]
sortLE _  [] = []
sortLE le (x:xs) =
  case partition (le x) xs of
    (ge, lt) -> sortLE le lt ++ (x : sortLE le ge)

last :: forall a . [a] -> a
last [] = error "last: []"
last [x] = x
last (_:xs) = last xs

init :: forall a . [a] -> [a]
init [] = error "init: []"
init [_] = []
init (x:xs) = x : init xs

anySame :: forall a . Eq a => [a] -> Bool
anySame = anySameBy (==)

anySameBy :: forall a . (a -> a -> Bool) -> [a] -> Bool
anySameBy _ [] = False
anySameBy eq (x:xs) = elemBy eq x xs || anySameBy eq xs

iterate :: forall a . (a -> a) -> a -> [a]
iterate f x = x : iterate f (f x)

iterate' :: (a -> a) -> a -> [a]
iterate' f x =
  let x' = f x
  in x' `seq` (x : iterate' f x')

substString :: forall a . Eq a => [a] -> [a] -> [a] -> [a]
substString _ _ [] = []
substString from to xs@(c:cs) | Just rs <- stripPrefix from xs = to ++ substString from to rs
                              | otherwise = c : substString from to cs

group :: Eq a => [a] -> [[a]]
group = groupBy (==)

groupBy :: (a -> a -> Bool) -> [a] -> [[a]]
groupBy _  []     =  []
groupBy eq (x:xs) =  (x:ys) : groupBy eq zs
  where (ys,zs) = span (eq x) xs

scanl :: (b -> a -> b) -> b -> [a] -> [b]
scanl f = rec
  where rec q ls = q : case ls of
                         []   -> []
                         x:xs -> rec (f q x) xs

scanl' :: (b -> a -> b) -> b -> [a] -> [b]
scanl' f = rec
  where rec q ls = q : case ls of
                         []   -> []
                         x:xs -> let y = f q x in seq y (rec y xs)

scanl1 :: (a -> a -> a) -> [a] -> [a]
scanl1 f (x:xs) = scanl f x xs
scanl1 _ []     = []

scanr :: (a -> b -> b) -> b -> [a] -> [b]
scanr f z = rec
  where rec []     =  [z]
        rec (x:xs) =  f x q : qs
              where qs@(q:_) = rec xs

scanr1 :: (a -> a -> a) -> [a] -> [a]
scanr1 f = rec
  where rec []     = []
        rec [x]    = [x]
        rec (x:xs) = f x q : qs
              where qs@(q:_) = rec xs

isSubsequenceOf :: (Eq a) => [a] -> [a] -> Bool
isSubsequenceOf []       _                 = True
isSubsequenceOf _        []                = False
isSubsequenceOf a@(x:a') (y:b) | x == y    = isSubsequenceOf a' b
                               | otherwise = isSubsequenceOf a b

uncons :: [a] -> Maybe (a, [a])
uncons []     = Nothing
uncons (x:xs) = Just (x, xs)

unsnoc :: [a] -> Maybe ([a], a)
unsnoc [] = Nothing
unsnoc xs = Just (init xs, last xs)

singleton :: a -> [a]
singleton x = [x]

transpose :: [[a]] -> [[a]]
transpose [] = []
transpose ([] : xss) = transpose xss
transpose ((x : xs) : xss) = combine x hds xs tls
  where
    (hds, tls) = unzip [(hd, tl) | hd : tl <- xss]
    combine y h ys t = (y:h) : transpose (ys:t)

subsequences :: [a] -> [[a]]
subsequences xs = [] : sub xs
  where sub []     = []
        sub (x:xs) = [x] : foldr f [] (sub xs)
          where f ys r = ys : (x : ys) : r

permutations :: [a] -> [[a]]
permutations axs = axs : perms axs []
  where
    perms []     _  = []
    perms (t:ts) is = foldr interleave (perms ts (t:is)) (permutations is)
      where
        interleave xs r = snd $ interleave' id xs r
        interleave' _ []     r = (ts, r)
        interleave' f (y:ys) r = let (us, zs) = interleave' (f . (y:)) ys r
                                 in  (y:us, f (t:y:us) : zs)

mapAccumL :: (acc -> x -> (acc, y)) -> acc -> [x] -> (acc, [y])
mapAccumL _ s []     = (s, [])
mapAccumL f s (x:xs) = (s'',y:ys)
  where (s', y ) = f s x
        (s'',ys) = mapAccumL f s' xs

mapAccumR :: (acc -> x -> (acc, y)) -> acc -> [x] -> (acc, [y])
mapAccumR _ s []     = (s, [])
mapAccumR f s (x:xs) = (s'', y:ys)
  where (s'',y ) = f s' x
        (s', ys) = mapAccumR f s xs

unfoldr :: (b -> Maybe (a, b)) -> b -> [a]
unfoldr gen b =
  case gen b of
    Nothing -> []
    Just (a, b') -> a : unfoldr gen b'

elemIndex :: Eq a => a -> [a] -> Maybe Int
elemIndex x xs = findIndex (x ==) xs

elemIndices :: Eq a => a -> [a] -> [Int]
elemIndices x xs = findIndices (x ==) xs

findIndices :: (a -> Bool) -> [a] -> [Int]
findIndices p = rec 0
  where rec _ [] = []
        rec i (x:xs) | p x = i : rec (i+1) xs
                     | otherwise = rec (i+1) xs

findIndex :: (a -> Bool) -> [a] -> Maybe Int
findIndex p xs =
  case findIndices p xs of
    [] -> Nothing
    i : _ -> Just i

lines :: String -> [String]
lines [] = []
lines s =
  case span (not . (== '\n')) s of
    (l, s') ->
      case s' of
        [] -> [l]
        _:s'' -> l : lines s''

unlines :: [String] -> String
unlines = concatMap (++ ['\n'])

words :: String -> [String]
words s =
  case dropWhile isSpace s of
    [] -> []
    s' -> w : words s''
      where (w, s'') = span (not . isSpace) s'

unwords :: [String] -> String
unwords ss = intercalate [' '] ss

sortOn :: Ord b => (a -> b) -> [a] -> [a]
sortOn f = map snd . sortBy (comparing fst) . map (\x -> let y = f x in y `seq` (y, x))

insert :: Ord a => a -> [a] -> [a]
insert e ls = insertBy (compare) e ls

insertBy :: (a -> a -> Ordering) -> a -> [a] -> [a]
insertBy _   x [] = [x]
insertBy cmp x ys@(y:ys') =
  case cmp x y of
    GT -> y : insertBy cmp x ys'
    _  -> x : ys

maximumBy :: (a -> a -> Ordering) -> [a] -> a
maximumBy _ []   =  error "List.maximumBy: []"
maximumBy cmp xs =  foldl1 maxBy xs
  where
    maxBy x y = case cmp x y of
                  GT -> x
                  _  -> y

minimumBy :: (a -> a -> Ordering) -> [a] -> a
minimumBy _ []   =  error "List.minimumBy: []"
minimumBy cmp xs =  foldl1 minBy xs
  where
    minBy x y = case cmp x y of
                  GT -> y
                  _  -> x

genericLength :: (Num i) => [a] -> i
genericLength []    = 0
genericLength (_:l) = 1 + genericLength l

genericTake :: (Integral i, Ord i) => i -> [a] -> [a]
genericTake n _ | n <= 0 = []
genericTake _ []         = []
genericTake n (x:xs)     = x : genericTake (n-1) xs

genericDrop :: (Integral i, Ord i) => i -> [a] -> [a]
genericDrop n xs | n <= 0 = xs
genericDrop _ []          = []
genericDrop n (_:xs)      = genericDrop (n-1) xs

genericSplitAt :: (Integral i, Ord i) => i -> [a] -> ([a], [a])
genericSplitAt n xs = (genericTake n xs, genericDrop n xs)

genericIndex :: (Integral i, Ord i) => [a] -> i -> a
genericIndex (x:_)  0 = x
genericIndex (_:xs) n | n > 0     = genericIndex xs (n-1)
                      | otherwise = error "List.genericIndex: < 0"
genericIndex _ _                  = error "List.genericIndex: index too large."

genericReplicate :: (Integral i, Ord i) => i -> a -> [a]
genericReplicate n x = genericTake n (repeat x)
