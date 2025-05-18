with Ada.Characters.Latin_1;

package MyStringTokeniser with SPARK_Mode is

   type TokenExtent is record
      Start : Positive;
      Length : Natural;
   end record;
   -- Index:     1 2 3 4 5 6 7 8 9
   -- String:    p u s h 1   1 2 3

   type TokenArray is array(Positive range <>) of TokenExtent;
   -- TokenArray [
   -- TokenExtent{start,natural}]

   function Is_Whitespace(Ch : Character) return Boolean is
     (Ch = ' ' or Ch = Ada.Characters.Latin_1.LF or
        Ch = Ada.Characters.Latin_1.HT);
   -- Task 1 Add comments to the file mystringtokeniser.ads describing each part of the postcondition
   -- of the Tokenise procedure. For each part of its postcondition, you need to describe
   -- what that part is saying and why it is necessary to have it as part of the postcondition.

   procedure Tokenise(S : in String; Tokens : in out TokenArray; Count : out Natural) with
     Pre => (if S'Length > 0 then S'First <= S'Last) and Tokens'First <= Tokens'Last,

   -- Count <= Tokens'Length
   -- When comment out 102:90 medium: array index check might fail (e.g. when I = 6 and TokStr'First = 5 and TokStr'Last = 5)
   -- What part is saying:
   --    The number of tokens extracted (Count) will not exceed the number of TokenExtent entries available in the Tokens array i.e 5.
   -- Why it is necessary:
   --    This ensures that accessing elements Tokens(1..Count) is safe and will not go out of bounds.
   --    Without this, SPARK cannot verify array accesses like T(I), and a proof failure like "array index check might fail" may occur.
     Post => Count <= Tokens'Length and
     (for all Index in Tokens'First..Tokens'First+(Count-1) =>
          (Tokens(Index).Start >= S'First and
          Tokens(Index).Length > 0) and then
            Tokens(Index).Length-1 <= S'Last - Tokens(Index).Start);
   --


end MyStringTokeniser;
