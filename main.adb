pragma SPARK_Mode (On);

with MyCommandLine;
with MyString;
with MyStringTokeniser;
with StringToInteger;
with PIN;
with MemoryStore;
with Calculator;

with Ada.Text_IO;use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Long_Long_Integer_Text_IO;
with Interfaces;

procedure Main is
   --  Helper instantiation for bounded lines
   package Lines is new MyString (Max_MyString_Length => 2048);
   subtype Int32 is Interfaces.Integer_32; 
   --  declare a instance of Calculator
   C    : Calculator.Calculator;
   S    : Lines.MyString;

   --  Memory database demo
   Mem  : MemoryStore.Database;
   Loc1 : MemoryStore.Location_Index := 10; 
   --  PIN demo
   PIN1 : PIN.PIN := PIN.From_String ("1234");
   PIN2 : PIN.PIN := PIN.From_String ("1234");
   
   -- its prompt indicates whether it is in the locked or the unlocked state
   LOCKED_PROMPT: constant String := "locked>";
   UNLOCKED_PROMPT: constant String := "unlocked>";
   
begin
   ------------------------------------------------------------------
   --  Command-line 
   ------------------------------------------------------------------
--     Put(MyCommandLine.Command_Name); Put_Line(" is running!");
--     Put("I was invoked with "); Put(MyCommandLine.Argument_Count,0); Put_Line(" arguments.");
--     -- No arguement 
--     for Arg in 1..MyCommandLine.Argument_Count loop
--        Put("Argument "); Put(Arg,0); Put(": """);
--        Put(MyCommandLine.Argument(Arg)); Put_Line("""");
--     end loop;

   -- check command
   if ( MyCommandLine.Argument_Count /= 1 ) then
      Put_Line("Wrong Command: Expected 1 argument");
   elsif not Calculator.Is_Valid_Pin(MyCommandLine.Argument(1)) then
      Put_Line("Wrong Command: PIN must be 4 digits"); 
   end if;
   
   
   Calculator.Init(c,PIN.From_String(MyCommandLine.Argument(1)));
   MemoryStore.Init (Mem);
   
   loop
   declare
         T : MyStringTokeniser.TokenArray(1..5) := (others => (Start => 1, Length => 0));
         NumTokens : Natural;
         Command : Lines.MyString;
         Argument:Lines.MyString;
   begin
      -- Prompt
      if Calculator.Is_Locked(C) then
         Put(LOCKED_PROMPT);
      else
         Put(UNLOCKED_PROMPT);
      end if;

      -- Read and tokenize
      Lines.Get_Line(S);
      MyStringTokeniser.Tokenise(Lines.To_String(S), T, NumTokens);

      if NumTokens < 1 then
         Put_Line("Empty entry!");
         return;
      elsif NumTokens > 3 then
         Put_Line("Too many arguments!");
         return;
      end if;

      -- Get command
      Command := Lines.Substring(S, T(1).Start, T(1).Start + T(1).Length - 1);

      if NumTokens = 1 then
         if Calculator.Is_Locked(C) then
            Put_Line("Invalid operation: Calculator is locked!");
            return;
         else
            declare
               Op : String := Lines.To_String(Command);
            begin
               if Lines.Equal(Command, Lines.From_String("+")) or else
                  Lines.Equal(Command, Lines.From_String("-")) or else
                  Lines.Equal(Command, Lines.From_String("*")) or else
                  Lines.Equal(Command, Lines.From_String("/")) then
                  Calculator.Calculation(C, Op);

               elsif Lines.Equal(Command, Lines.From_String("pop")) then
                  declare
                     Pop_num : Int32;
                  begin
                     Calculator.Pop(C, Pop_num);
                     Put_Line("Popped: " & Int32'Image(Pop_num));
                  end;

               elsif Lines.Equal(Command, Lines.From_String("list")) then
                  MemoryStore.Print(Mem);

               else
                  Put_Line("Syntax_Exception: Unrecognized command!");
               end if;
            end;
         end if;
         elsif NumTokens = 2 then
            Argument := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
            declare
               ArgumentString: String := Lines.To_String(Argument);
            begin
            if Calculator.Is_Locked(C) then
               -- unlock
               if Lines.Equal(Command, Lines.From_String("unlock")) then
                  Calculator.Unlock(C,PIN.From_String(ArgumentString));
               else
                  Put_Line("Invalid operation: Calculator is locked!");
                  return;
               end if;
               
            else
               -- lock
               if Lines.Equal(Command, Lines.From_String("lock")) then
                  Calculator.Lock(C,PIN.From_String(ArgumentString));
               -- push1
               elsif Lines.Equal(Command, Lines.From_String("push1")) then
                  Calculator.Push_1(C,Int32(StringToInteger.From_String(ArgumentString)));
               elsif Lines.Equal(Command, Lines.From_String("loadFrom")) then
                  Calculator.Load_From(C,Mem,StringToInteger.From_String(ArgumentString));
               elsif Lines.Equal(Command, Lines.From_String("storeTo")) then                       
                  Calculator.Store_To(C,Mem,StringToInteger.From_String(ArgumentString)); 
               elsif Lines.Equal(Command, Lines.From_String("remove")) then 
                  MemoryStore.Remove(Mem,StringToInteger.From_String(ArgumentString));
               end if; 
            end if;
            end;
            
         elsif NumTokens = 3 then
            if Calculator.Is_Locked(C) then
               Put_Line("Invalid operation: Calculator is locked!");
            return;
            else
               declare
                  Op : String := Lines.To_String(Command);
                  Argument_1:Lines.MyString := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
                  Argument_2:Lines.MyString := Lines.Substring(S,T(3).Start,T(3).Start+T(3).Length-1);
                  Argument1_String: String := Lines.To_String(Argument_1);
                  Argument2_String: String := Lines.To_String(Argument_2);
               begin
                  if Lines.Equal(Command, Lines.From_String("push2")) then
                     Calculator.Push_2(C,Int32(StringToInteger.From_String(Argument1_String))
                                       ,Int32(StringToInteger.From_String(Argument2_String)));
                  else
                     Put_Line("Invalid operation: Calculator is locked!");
                     return;
                  end if;
               end;
            end if;
            
                  
                  
                  
               
      else
         Put_Line("Syntax_Exception: Only one-word commands allowed here.");
      end if;
   end;
end loop;

      
   
   
--     ------------------------------------------------------------------
--     --  MemoryStore CRUD(Create, Read, Update, Delete) demo
--     ------------------------------------------------------------------
--     
--     -- Init memory stack with 
--     MemoryStore.Init (Mem);
--  
--     Put_Line ("Storing 50 at location 10 ...");
--     MemoryStore.Put (Mem, Loc1, 50); 
--     -- Mem :MemoryStore.Database {
--     --   Mem: Mem_Array [{10,50}]
--     --   Cnt: 1
--     -- }
--  
--     Put ("Location 10 now holds: ");
--     Ada.Integer_Text_IO.Put (Integer (MemoryStore.Get (Mem, Loc1)), 0);
--     -- Put(50,0);  -- "50"
--     -- Put(50,5);  -- "     50" (4 space + 50)
--     New_Line;
--  
--     Put_Line ("Listing defined locations:");
--     MemoryStore.Print (Mem);
--     -- Pretty-print for the "list" command,"   10 => 50"
--  
--     Put_Line ("Removing location 10 ...");
--     MemoryStore.Remove (Mem, Loc1);
--  
--     if MemoryStore.Has (Mem, Loc1) then
--        Put_Line ("Location 10 is still defined! (unexpected)");
--     else
--        Put_Line ("Location 10 successfully removed.");
--     end if;
--     -- Mem :MemoryStore.Database {
--     --   Mem: Mem_Array []
--     --   Cnt: 0
--     -- }
--     
--      ------------------------------------------------------------------
--     --  Calculator demo
--      ------------------------------------------------------------------
--     -- Init Calculator stack with 
--     MemoryStore.Init (Mem);
--  
--     Put_Line ("Storing 50 at location 10 ...");
--     MemoryStore.Put (Mem, Loc1, 50); 
--     -- Mem :MemoryStore.Database {
--     --   Mem: Mem_Array [{10,50}]
--     --   Cnt: 1
--     -- }
--     
--     
--     ------------------------------------------------------------------
--     --  Tokeniser demo
--     ------------------------------------------------------------------
--     Put_Line("Reading a line of input. Enter some text (at most 3 tokens): ");
--     -- most 3 token Push2 a b 
--     Lines.Get_Line(S); -- 
--     Put_Line("Splitting the text into at most 5 tokens");
--     
--     declare
--        T : MyStringTokeniser.TokenArray(1..5) := (others => (Start => 1, Length => 0));
--        --  T(1) = TokenExtent(Start => 1, Length => 0) 
--        --  T(2) = TokenExtent(Start => 1, Length => 0) 
--        --  T(3) = TokenExtent(Start => 1, Length => 0) 
--        --  T(4) = TokenExtent(Start => 1, Length => 0) 
--        --  T(5) = TokenExtent(Start => 1, Length => 0) 
--        NumTokens : Natural;
--     begin
--        MyStringTokeniser.Tokenise(Lines.To_String(S),T,NumTokens);
--        
--           -- Index:     1 2 3 4 5 6 7 8 9
--           -- String:    p u s h 1   1 2 3
--           --  T(1) = TokenExtent(Start => 1, Length => 5) -- "push1"
--           --  T(2) = TokenExtent(Start => 7, Length => 3) -- "123"
--           --  T(3) = (Start => 1, Length => 0) 
--        Put("You entered "); Put(NumTokens); Put_Line(" tokens.");
--        for I in 1..NumTokens loop
--           declare
--              TokStr : String := Lines.To_String(Lines.Substring(S,T(I).Start,T(I).Start+T(I).Length-1));
--           begin
--              Put("Token "); Put(I); Put(" is: """);
--              Put(TokStr); Put_Line("""");
--           end;
--        end loop;
--        if NumTokens > 3 then
--           Put_Line("You entered too many tokens --- I said at most 3");
--        end if;
--     end;
--     
--     ------------------------------------------------------------------
--     --  PIN equality demo
--     ------------------------------------------------------------------
--     If PIN."="(PIN1,PIN2) then
--        Put_Line("The two PINs are equal, as expected.");
--     end if;
--     
--     ------------------------------------------------------------------
--     --  32-bit overflow / parsing demo (unchanged)
--     ------------------------------------------------------------------
--     declare
--        Smallest_Integer : Integer := StringToInteger.From_String("-2147483648");
--        R : Long_Long_Integer := 
--          Long_Long_Integer(Smallest_Integer) * Long_Long_Integer(Smallest_Integer);
--     begin
--        Put_Line("This is -(2 ** 32) (where ** is exponentiation) :");
--        Put(Smallest_Integer); New_Line;
--        
--        if R < Long_Long_Integer(Integer'First) or
--           R > Long_Long_Integer(Integer'Last) then
--           Put_Line("Overflow would occur when trying to compute the square of this number");
--        end if;
--           
--     end;
--     Put_Line("2 ** 32 is too big to fit into an Integer...");
--     Put_Line("Hence when trying to parse it from a string, it is treated as 0:");
--     Put(StringToInteger.From_String("2147483648")); New_Line;
   
      
end Main;
