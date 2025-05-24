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
with Ada.Characters.Latin_1;

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
   --  FATAL ERROR: Command-line argument validation (exit immeadiately)
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
      Put_Line("SYSTEM_ERROR: Expected 1 argument (master PIN)");
      return;
   elsif not Calculator.Is_Valid_Pin(MyCommandLine.Argument(1)) then
      Put_Line("INPUT_ERROR: PIN must be 4 digits (0000-9999)");
      return;
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


         
      ------------------------------------------------------------------
      --  FATAL ERROR: Input validation (exit immeadiately)
      ------------------------------------------------------------------
      
      -- check input length
      if Lines.Length(S) > 2048 then
         Put_Line("INPUT_ERROR: Input too long (max 2048 characters)");
         return;
      end if;
      
      
      -- check empty input
      if Lines.Length(S) = 0 then
         Put_Line("INPUT_ERROR: Empty input not allowed");
         return;
      end if;
         
        
      -- check nul character
      for I in 1..Lines.Length(S) loop
         if Lines.To_String(S)(I) = Ada.Characters.Latin_1.NUL then
            Put_Line("INPUT_ERROR: NUL characters not allowed");
            return;
         end if;
      end loop; 
          
         
         
      ------------------------------------------------------------------
      --  FATAL ERROR: Syntax validation (exit immeadiately)
      ------------------------------------------------------------------
         
      MyStringTokeniser.Tokenise(Lines.To_String(S), T, NumTokens);
      
      -- Empty command   
      if NumTokens < 1 then
         Put_Line("SYNTAX_ERROR: Empty command");
         return;
      elsif NumTokens > 3 then
         Put_Line("SYNTAX_ERROR: Too many arguments");
         return;
      end if;


      ------------------------------------------------------------------
      --  NumTokens = 1
      ------------------------------------------------------------------
         
         
      -- Get command
      Command := Lines.Substring(S, T(1).Start, T(1).Start + T(1).Length - 1);
         
         
      if NumTokens = 1 then
         -- Check Lock status
         if Calculator.Is_Locked(C) then
            Put_Line("LOCK_ERROR: Calculator is locked");
         else
            declare
               Op : String := Lines.To_String(Command);
            begin
               if Lines.Equal(Command, Lines.From_String("+")) or else
                  Lines.Equal(Command, Lines.From_String("-")) or else
                  Lines.Equal(Command, Lines.From_String("*")) or else
                  Lines.Equal(Command, Lines.From_String("/")) then
                  
                  -- Check #operands
                  if Calculator.Length(C) < 2 then  
                     Put_Line("STACK_ERROR: Need at least 2 operands");
                  else
                     Calculator.Calculation(C, Op);
                  end if;
               
               -- pop
               elsif Lines.Equal(Command, Lines.From_String("pop")) then
                  if Calculator.Length(C) = 0 then
                     Put_Line("STACK_ERROR: Cannot pop from empty stack");
                  else
                     declare
                        Pop_num : Int32;
                     begin
                        Calculator.Pop(C, Pop_num);
                        Put_Line("Popped: " & Int32'Image(Pop_num));
                     end;
                     end if;
                     
               -- list
               elsif Lines.Equal(Command, Lines.From_String("list")) then
                  MemoryStore.Print(Mem);
               
               -- Unknown command
               else
                  Put_Line("SYNTAX_ERROR: Unknown command!");
                  return;
                  end if;
            end;
         end if;
            
      ------------------------------------------------------------------
      --  NumTokens = 2
      ------------------------------------------------------------------
            
      elsif NumTokens = 2 then
         Argument := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
         declare
            ArgumentString: String := Lines.To_String(Argument);
         begin
            -- unlock
            if Lines.Equal(Command, Lines.From_String("unlock")) then
               -- already unlocked
               if not Calculator.Is_Locked(C) then
                  Put_Line("LOCK_ERROR: Calculator already unlocked");
               -- invalid pin format
               elsif not Calculator.Is_Valid_Pin(ArgumentString) then
                  Put_Line("INPUT_ERROR: Invalid PIN format");
                  return;
               else
                  Calculator.Unlock(C, PIN.From_String(ArgumentString));
               end if;

            elsif Calculator.Is_Locked(C) then
               Put_Line("LOCK_ERROR: Calculator is locked");



            else
               -- lock
               if Lines.Equal(Command, Lines.From_String("lock")) then
                  -- invalid pin format
                  if not Calculator.Is_Valid_Pin(ArgumentString) then
                     Put_Line("INPUT_ERROR: Invalid PIN format");
                     return;
                  else
                     Calculator.Lock(C, PIN.From_String(ArgumentString));
                  end if;
		
               -- push1
               elsif Lines.Equal(Command, Lines.From_String("push1")) then
                  if Calculator.Length(C) >= 512 then
                     Put_Line("STACK_ERROR: Stack is full");
                  else
                     Calculator.Push_1(C,Int32(StringToInteger.From_String(ArgumentString)));
                  end if;

               -- loadFrom
               elsif Lines.Equal(Command, Lines.From_String("loadFrom")) then
                  declare
                     Location : Integer := StringToInteger.From_String(ArgumentString);
                  begin

                     if Calculator.Length(C) >= 512 then
                        Put_Line("STACK_ERROR: Stack is full");
                     elsif not MemoryStore.Has(Mem, Location) then
                        Put_Line("MEMORY_ERROR: No value at location");
                     else
                        Calculator.Load_From(C,Mem,StringToInteger.From_String(ArgumentString));
                     end if;
                  end;
               
               -- storeTo
               elsif Lines.Equal(Command, Lines.From_String("storeTo")) then 
                  if Calculator.Length(C) = 0 then
                     Put_Line("STACK_ERROR: Cannot store from empty stack");
                  else
                     Calculator.Store_To(C,Mem,StringToInteger.From_String(ArgumentString)); 
                  end if;

               -- remove
               elsif Lines.Equal(Command, Lines.From_String("remove")) then 
                  MemoryStore.Remove(Mem,StringToInteger.From_String(ArgumentString));
               
               -- unknown command
               else
                  Put_Line("SYNTAX_ERROR: Unknown command");
                  return;
               end if; 
            end if;
         end;
            
      ------------------------------------------------------------------
      --  NumTokens = 3
      ------------------------------------------------------------------
      elsif NumTokens = 3 then
         -- is locked
         if Calculator.Is_Locked(C) then
            Put_Line("LOCK_ERROR: Calculator is locked");
         else
            declare
               Argument_1:Lines.MyString := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
               Argument_2:Lines.MyString := Lines.Substring(S,T(3).Start,T(3).Start+T(3).Length-1);
               Argument1_String: String := Lines.To_String(Argument_1);
               Argument2_String: String := Lines.To_String(Argument_2);
            begin
               -- push2
               if Lines.Equal(Command, Lines.From_String("push2")) then
                  if Calculator.Length(C) >= 510 then
                     Put_Line("STACK_ERROR: Stack full, cannot push 2 values");
                  else
                     Calculator.Push_2(C,
                                       Int32(StringToInteger.From_String(Argument1_String)),
                                       Int32(StringToInteger.From_String(Argument2_String)));
                  end if;
               -- unknwon command
               else
                  Put_Line("SYNTAX_ERROR: Unknown command");
                  return;
               end if;
            end;
         end if;
            
                  
                  
                  
               
      else
         Put_Line("SYNTAX_ERROR: Invalid number of arguments");
         return;
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
