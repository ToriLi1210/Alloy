-- Author
-- Tori(Hanying) Li, Student ID: 1181148
-- Sean(Aoxiang) Xiao, Student ID: 1174270
-- To prove our implementation is secure, the following security properties are satisfied:

--  The arithmetic operations ("+", "-", "*", "/"), load, store, remove, and lock operations can
--  only ever be performed when the calculator is in the unlocked state.

--  To ensure operations can only be performed when the calculator is in the unlocked state, 
--  we use the precondition Pre=>not Is_Locked(C) in each operation's contract. 
--  This enforces that Is_Locked(C) = False (calculator in unlocked state) must hold for an operation to execute. 
--  If the precondition does not hold (i.e., Is_Locked(C) = True), 
--  the operation cannot be performed as it would violate the contract 
--  and raise a exception "LOCK_ERROR: Invalid input, Calculator is locked Please unlock first" and exit calaculator immediately.
--  We also use the postcondition Post=>Is_Locked(C) = Is_Locked(C'Old) to ensure that the lock state remains unchanged after the operation executes, 
--  guaranteeing that operations performed in the unlocked state maintain that state. 
--  Furthermore, a assertation pragma Assert (not Calculator.Is_Locked(C)) statements 
--  is used to verify the unlocked state before and after operation execution.


-- The Unlock operation can only ever be performed when the calculator is in the locked state.

--  To ensure that the Unlock operation is only performed when the calculator is in the locked state, 
--  we specify the precondition Pre => Is_Locked(C) the Unlock procedure’s contract. 
--  This enforces that the calculator must be locked. If the calculator is already unlocked, 
--  the operation cannot be performed as it would violate the contract 
--  and issue a warning message "Already unlocked" instead of proceeding with the unlock operation. 
--  We also use pragma Assert (not Calculator.Is_Locked(C)) before executing to ensure that the calculator is unlocked, 
--  and pragma Assert (Calculator.Is_Locked(C)) after successful locking to verify that the lock transition has occurred. 
--  These SPARK annotations and runtime assertions together guarantee that unlocking only happens from a locked state, and improper transitions are caught either by formal proof or runtime checks.

-- The Lock operation, when it is performed, should update the master PIN with the new PIN that is supplied.

-- To ensure that the Lock operation correctly updates the calculator’s master PIN with the newly supplied PIN string, 
-- we specify the postcondition Post => Get_PIN(C) = PIN.From_String(P) in the contract of the Lock procedure. 
-- This guarantees that after locking, the internal Master_PIN field of the calculator is updated to the PIN version of the input string. 
-- The precondition Pre => not Is_Locked(C) and Is_Valid_Pin(P) ensures that lock calculator with new PIN is only allowed 
-- when the calculator is currently unlocked and the input string is a valid PIN. 
-- Additionally, a runtime assertion pragma Assert(Calculator.Is_Locked(C)) is placed immediately after locking to 
-- confirm that the state transition to locked has occurred.
-- Together, these SPARK annotations and assertions ensure both functional correctness (PIN is updated) and secure state transition (calculator becomes locked).

-- The stack operation "pop","push1","push2" can only ever be performed when they do not cause stack underflow or overflow.

-- To verify this, we use SPARK preconditions such as Pre => Length(C) /= 0 in Pop to prevent popping from an empty stack, 
-- and Pre => Can_Push_N(C, N) in Push_1 and Push_2 to ensure the stack has enough space before pushing new values. 
-- These annotations enforce safe bounds on stack size and guarantee that no stack operation will exceed the defined capacity (Calculator_Stack_Capacity)

-- The memory location operation "remove","storeTo","loadFrom" can only ever be performed when they do not cause memory access violations,such as reading from undefined locations or overwriting existing entries.

-- To verify this, we use SPARK preconditions: Pre => MemoryStore.Has(D, Loc) in loadFrom and remove guarantees that a value exists before loading, 
-- and Pre => not MemoryStore.Has(D, Loc) in storeTo ensures a location is not overwritten. 
-- Additionally, bounds checks such as Loc in 1 .. MemoryStore.Max_Locations prevent invalid memory index access. These constraints collectively enforce memory safety and data consistency.

-- The arithmetic operations (“+”, “-”, “*”, “”) can only ever be performed when they do not cause 32-bit integer overflow or divide-by-zero.

-- To verify this, we use SPARK preconditions that restrict input values to safe ranges(32-bit Integer'First,32-bit Integer'Last). 
-- The helper function Addition, Subtraction, and Multiplication all include checks that the result lies within the bounds of a 32-bit signed integer using expressions 
-- like Pre => Long_Long_Integer(Number_1) + Long_Long_Integer(Number_2) in Int32'Range. 
-- The Division operation uses Pre => Number_2 /= 0 and a special case Number_1 = Int32'First and Number_2 /= -1 to avoid overflow caused by dividing the smallest negative number by -1. 
-- These properties guarantee arithmetic safety and prevent runtime exceptions due to invalid calculations.

-- The lock state of the calculator (Is_Locked(C)) can only be modified when the Lock and Unlock operations are successfully performed, while all other valid operations preserve the unchanged state.

-- To verify this, we use SPARK postconditions such as Post => Is_Locked(C) = Is_Locked(C'Old) in all procedures except Lock and Unlock, 
-- ensuring that the lock status is not altered during their execution. In contrast, Lock and Unlock have contracts that permit controlled state transitions. 
-- Additionally, we place pragma Assert (not Calculator.Is_Locked(C)) before and after operations like Calculation and Pop to ensure these are only executed in the unlocked state. 
-- Furthermore, for valid commands that receive correct syntax and arguments but cannot complete due to runtime conditions (e.g., stack overflow or empty stack), 
-- We allow the system to issue a warning without performing the operation or exiting, ensuring that all calculator states—including the lock status—remain unchanged in such cases.

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
   --  Memory database demo
   --     Loc1 : MemoryStore.Location_Index := 10; 
   --  PIN demo
   --  PIN1 : PIN.PIN := PIN.From_String ("1234");
   --  PIN2 : PIN.PIN := PIN.From_String ("1234");

   -- its prompt indicates whether it is in the locked or the unlocked state
   LOCKED_PROMPT: constant String := "locked>";
   UNLOCKED_PROMPT: constant String := "unlocked>";
   MAX_INPUT_LENGTH: constant Integer := 2048;
   MIN_TOKEN: constant Integer:=1;
   MAX_TOKEN: constant Integer:=3;
   
   
   
   package Lines is new MyString (Max_MyString_Length => MAX_INPUT_LENGTH);
    --  Helper instantiation for bounded lines
   subtype Int32 is Interfaces.Integer_32; 
   --  declare a instance of Calculator
   C    : Calculator.Calculator;
   S    : Lines.MyString;
   Mem  : MemoryStore.Database;
   
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

   -- check input command
   if ( MyCommandLine.Argument_Count /= 1 ) then
      Put_Line("SYSTEM_ERROR: Expected 1 argument (master PIN)");
      return;
   elsif not Calculator.Is_Valid_Pin(MyCommandLine.Argument(1)) then
      Put_Line("INPUT_ERROR: PIN must be 4 digits (0000-9999)");
      return;
   end if;
   
  
   Calculator.Init(C,MyCommandLine.Argument(1));
   MemoryStore.Init (Mem);
   
   loop

      pragma Loop_Invariant (Calculator.Length(C) in 0..Calculator.Calculator_Stack_Capacity);
      
      declare
         T : MyStringTokeniser.TokenArray(1..MAX_TOKEN) := (others => (Start => 1, Length => 0));
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
      
         -- check if input length exceeds the maximum character length
         if Lines.Length(S) > MAX_INPUT_LENGTH then
            Put_Line("INPUT_ERROR: Input too long (max 2048 characters)");
            exit;
         end if;
      
      
         -- check if input is empty input
         if Lines.Length(S) = 0 then
            Put_Line("INPUT_ERROR: Empty input not allowed");
            exit;
         else
            -- check if input is whitespace
            declare
               Input_Str : String := Lines.To_String(S);
               Is_Blank  : Boolean := True;
            begin
               for C in Input_Str'Range loop
                  pragma Loop_Invariant (C in Input_Str'Range);
                  pragma Loop_Invariant (if C > Input_Str'First then 
                                           (for all J in Input_Str'First..C-1 => Input_Str(J) = ' '));
                  if Input_Str(C) /= ' ' then
                     Is_Blank := False;
                     exit;
                  end if;
               end loop;

               if Is_Blank then
                  Put_Line("INPUT_ERROR: Input is only whitespace");
                  exit;
               end if;
            end;
         end if;
        

         -- check nul character
         for I in 1..Lines.Length(S) loop
            pragma Loop_Invariant (I in 1..Lines.Length(S));
            pragma Loop_Invariant (for all J in 1..I-1 => 
                                     Lines.To_String(S)(J) /= Ada.Characters.Latin_1.NUL);
            if Lines.To_String(S)(I) = Ada.Characters.Latin_1.NUL then
               Put_Line("INPUT_ERROR: NUL characters not allowed");
               exit;
            end if;
         end loop;
         

         -- check trailing whitespace (space, tab, etc.)
         declare
            Last_Char : Character := Lines.To_String(S)(Lines.To_String(S)'Last);
         begin
            if Last_Char = ' ' or Last_Char = Ada.Characters.Latin_1.HT then
               Put_Line("INPUT_ERROR: Extra whitespace at end of command");
               exit;
            end if;
         end;   

         
         ------------------------------------------------------------------
         --  FATAL ERROR: Syntax validation (exit immeadiately)
         ------------------------------------------------------------------
         
         MyStringTokeniser.Tokenise(Lines.To_String(S), T, NumTokens);
      
         -- Empty command   
         if NumTokens < MIN_TOKEN then
            Put_Line("SYNTAX_ERROR: Empty command");
            exit;
         elsif NumTokens > MAX_TOKEN then
            Put_Line("SYNTAX_ERROR: Too many arguments");
            exit;
         end if;

         ------------------------------------------------------------------
         --  NumTokens = 1
         ------------------------------------------------------------------
         
         
         -- Get command
         Command := Lines.Substring(S, T(1).Start, T(1).Start + T(1).Length - 1);
         
         
         if NumTokens = MIN_TOKEN then
            if Calculator.Is_Locked(C) then
               Put_Line("LOCK_ERROR: Invalid input, Calculator is locked Please unlock first");
               exit;
            else
               -- operation can only be performed in unlock status
               pragma Assert (not Calculator.Is_Locked(C));
               -- calculation   
               if Calculator.Is_Operator_Command(Lines.To_String(Command)) then
                  if Calculator.Length(C) < 2 then  
                     Put_Line("STACK_ERROR: Need at least 2 operands");
                  else
                     Calculator.Calculation(C, Lines.To_String(Command));
                     -- operations will not change state
                     pragma Assert (not Calculator.Is_Locked(C));
                  end if;
               elsif Lines.Equal(Command, Lines.From_String("pop")) then
                  if Calculator.Length(C) = 0 then
                     Put_Line("STACK_ERROR: Cannot pop from empty stack");
                  else
                     declare
                        Pop_num : Int32;
                     begin
                        -- operations will not change state
                        Calculator.Pop(C, Pop_num);
                        Put_Line("Popped: " & Int32'Image(Pop_num));
                        pragma Assert (not Calculator.Is_Locked(C));
                     end;
                  end if;
               elsif Lines.Equal(Command, Lines.From_String("list")) then
                  MemoryStore.Print(Mem);
                  pragma Assert (not Calculator.Is_Locked(C));
               else
                  Put_Line("SYNTAX_ERROR: Invalid Input!");
                  exit;
               end if;

            end if;
            
            ------------------------------------------------------------------
            --  NumTokens = 2 Invalid Input => Exit immediately
            ------------------------------------------------------------------
            
         elsif MIN_TOKEN < NumTokens and then NumTokens < MAX_TOKEN then
            Argument := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
            
            declare
               Arg_Str : String := Lines.To_String(Argument);
               Is_Arg_Blank : Boolean := True;
            begin
               for C of Arg_Str loop
                  if C /= ' ' then
                     Is_Arg_Blank := False;
                     exit;
                  end if;
               end loop;
      
               if Is_Arg_Blank then
                  Put_Line("INPUT_ERROR: Argument cannot be empty or whitespace");
                  exit;
               end if;
            end;
            
            declare
               ArgumentString: String := Lines.To_String(Argument);
            begin
               -- The Unlock operation can only ever be performed 
               -- when the calculator is in the locked state.
               if Calculator.Is_Locked(C) then
                  pragma Assert (Calculator.Is_Locked(C));
                  if Lines.Equal(Command, Lines.From_String("unlock")) then
                     -- invalid pin format 
                     if Calculator.Is_Valid_Pin(ArgumentString) then
                        if Calculator.Is_PIN(C,ArgumentString)then
                           Calculator.Unlock(C, ArgumentString);
                           
                           -- state changed locked -> unlocked
                           pragma Assert (not Calculator.Is_Locked(C));
                        else
                           Put_Line("UNLOCK_ERROR: Incorrect PIN");
                        end if;
                     
                     else
                        -- i.e unlock invalid
                        Put_Line("INPUT_ERROR: Invalid PIN format");
                        exit;
                     end if;
                     -- lock in locked state, operations not performed
                  elsif Lines.Equal(Command, Lines.From_String("lock"))then
                     if not Calculator.Is_Valid_Pin(ArgumentString) then
                        Put_Line("INPUT_ERROR: Invalid PIN format");
                        exit;
                     else
                        Put_Line("Already locked");
                     end if;
                  else 
                     Put_Line("LOCK_ERROR: Invalid input, Calculator is locked Please unlock first");
                     exit;
                  end if;
              -- unlock status
               else
                  pragma Assert (not Calculator.Is_Locked(C));
                  if Lines.Equal(Command, Lines.From_String("lock")) then
                     -- invalid pin format
                     if not Calculator.Is_Valid_Pin(ArgumentString) then
                        Put_Line("INPUT_ERROR: Invalid PIN format");
                        exit;
                     else
                        -- state changed unlock -> lock
                        Calculator.Lock(C, ArgumentString);
                        pragma Assert (Calculator.Is_Locked(C));
                        -- new masterpin
                        pragma Assert (Calculator.Is_PIN(C,ArgumentString)=True);
                     end if;
                  elsif Lines.Equal(Command, Lines.From_String("unlock"))then
                     if not Calculator.Is_Valid_Pin(ArgumentString) then
                        Put_Line("INPUT_ERROR: Invalid PIN format");
                        exit;
                     else
                        Put_Line("Already unlocked");
                     end if;
                     -- push1
                     -- unlock
                  else
                     -- check argument is integer/intger32
                     if Calculator.Is_Valid_Integer(ArgumentString) then

                        if Lines.Equal(Command, Lines.From_String("push1")) then
                           if not Calculator.Can_Push_N(C, 1) then
                              Put_Line("STACK_ERROR: Stack is full");
                           else
                              Calculator.Push_1(C,Int32(StringToInteger.From_String(ArgumentString)));
                              pragma Assert (not Calculator.Is_Locked(C));
                           end if;

                        -- loadFrom
                        elsif Lines.Equal(Command, Lines.From_String("loadFrom")) then
                           declare
                              Location : Integer := StringToInteger.From_String(ArgumentString);
                           begin
                        
                              if Location < 1 or Location > MemoryStore.Max_Locations then
                                 Put_Line("MEMORY_ERROR: Location must be between 1 and 256");
                              elsif not Calculator.Can_Push_N(C, 1) then
                                 Put_Line("STACK_ERROR: Stack is full");
                              elsif not MemoryStore.Has(Mem, Location) then
                                 Put_Line("MEMORY_ERROR: No value at location");
                              else
                                 Calculator.Load_From(C,Mem,Location);
                                 pragma Assert (not Calculator.Is_Locked(C));
                              end if;
                           end;
               
                           -- storeTo
                        elsif Lines.Equal(Command, Lines.From_String("storeTo")) then 
                           declare
                              Location : Integer := StringToInteger.From_String(ArgumentString);
                           begin
                              if Location < 1 or Location > MemoryStore.Max_Locations  then
                                 Put_Line("MEMORY_ERROR: Location must be between 1 and 256");
                              elsif Calculator.Length(C) = 0 then
                                 Put_Line("STACK_ERROR: Cannot store from empty stack");
                              elsif MemoryStore.Has(Mem,Location)then
                                 Put_Line("MEMORY_ERROR: The memory loc is defined");
                              else
                                 Calculator.Store_To(C,Mem,Location);
                                 pragma Assert (not Calculator.Is_Locked(C));
                              end if;
                           end;

                           -- remove
                        elsif Lines.Equal(Command, Lines.From_String("remove")) then
                     
                           declare
                              Location : Integer := StringToInteger.From_String(ArgumentString);
                           begin
                              if Location < 1 or Location > MemoryStore.Max_Locations then
                                 Put_Line("MEMORY_ERROR: Location must be an integer between 1 and 256");
                              elsif not MemoryStore.Has(Mem,Location) then
                                 Put_Line("MEMORY_ERROR: Cannot remove from undefined location");
                              else
                                 MemoryStore.Remove(Mem,StringToInteger.From_String(ArgumentString));
                                 pragma Assert (not Calculator.Is_Locked(C));
                              end if;
                           end;

                           -- unknown command
                        else
                           Put_Line("SYNTAX_ERROR: Invalid Input");
                           exit;
                        end if; 
                        
                     else
                        Put_Line("SYNTAX_ERROR: Argument must be Integer");
                        exit;
                     end if;
                  end if;
               end if;
            end;
              
                 
                     
            ------------------------------------------------------------------
            --  NumTokens = 3
            ------------------------------------------------------------------
         elsif NumTokens = MAX_TOKEN then
            -- is locked
            if Calculator.Is_Locked(C) then
               Put_Line("LOCK_ERROR: Invalid input, Calculator is locked Please unlock first");
               exit;
            else
               declare
                  Argument_1:Lines.MyString := Lines.Substring(S,T(2).Start,T(2).Start+T(2).Length-1);
                  Argument_2:Lines.MyString := Lines.Substring(S,T(3).Start,T(3).Start+T(3).Length-1);
                  Argument1_String: String := Lines.To_String(Argument_1);
                  Argument2_String: String := Lines.To_String(Argument_2);
               begin
                  pragma Assert (not Calculator.Is_Locked(C));
                  -- push2
                  if Lines.Equal(Command, Lines.From_String("push2")) then
                     if not Calculator.Can_Push_N(C, 2) then
                        Put_Line("STACK_ERROR: Stack full, cannot push 2 values");
                     elsif not (Calculator.Is_Valid_Integer(Argument1_String) and Calculator.Is_Valid_Integer(Argument2_String)) then
                        Put_Line("SYNTAX_ERROR: Argument must be Integer");
                        exit;
                     else
                        Calculator.Push_2(C,
                                          Int32(StringToInteger.From_String(Argument1_String)),
                                          Int32(StringToInteger.From_String(Argument2_String)));
                        pragma Assert (not Calculator.Is_Locked(C));
                     end if;
                     -- unknwon command
                  else
                     Put_Line("SYNTAX_ERROR: Invalid Input");
                     exit;
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
--     If F"="(PIN1,PIN2) then
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

