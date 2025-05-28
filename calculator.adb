with Ada.Text_IO;
use Ada.Text_IO;
with MemoryStore;
with Interfaces;
use Interfaces;
with PIN;
package body Calculator with SPARK_Mode is
   ---------------------------------------------------------------------------
   --  Initialisation
   ---------------------------------------------------------------------------
   procedure Init(C : out Calculator; Master_PIN: in String) is
   begin
      -- The calculator begins in the locked state.
      C.Locked:=True;
      -- User needs to supply master pin
      C.Masterpin:=PIN.From_String(Master_PIN);
      -- The size of operand stack is 0
      C.Length:=0;
      C.Operand_stack:=(others=>0);

   end Init;

   -- "+"
   function Addition(Number_1: in Int32; Number_2: in Int32) return Int32 is
   begin
      return Number_1+Number_2;
   end Addition;

   -- "-"
   function Subtraction(Number_1: in Int32; Number_2: in Int32) return Int32 is
   begin
      return Number_1-Number_2;
   end Subtraction;

   -- "*"
   function Multiplication(Number_1: in Int32; Number_2: in Int32) return Int32 is
   begin
      return Number_1*Number_2;
   end Multiplication;

   -- "/"
   function Division(Number_1: in Int32; Number_2: in Int32) return Int32 is
   begin
      return Number_1/Number_2;
   end Division;

   -- push1 <NAME>
   -- Push a number into the operand stack(Read and Modified) with a Int32(Read only)
   procedure Push_1(C:in out Calculator;Number_1:in Int32) is
   begin
      C.Length:=C.Length+1;
      -- since the index of operand stack starts with 1
      C.Operand_stack(C.Length):=Number_1;
   end Push_1;

   -- push2 <NAME> <NAME>
   -- Push 2 numbers into the operand stack with sequence(Read and Modified) with a Int32(Read only)
   procedure Push_2(C:in out Calculator;Number_1:in Int32;Number_2:in Int32) is
   begin
      Push_1(C,Number_1);
      Push_1(C,Number_2);
   end Push_2;

   -- pop
   -- remove 1 number from the top of operand stack and stored in Result
   procedure Pop(C:in out Calculator;Result:out Int32)is
   begin
      Result:=C.Operand_stack(C.Length);
      C.Length:=C.Length-1;
   end Pop;


   -- loadFrom <NAME>; loads the value stored at memory location loc and pushes it onto the operand stack
   procedure Load_From(C:in out Calculator;D : in MemoryStore.Database; Loc: in MemoryStore.Location_Index) is
   begin
      declare
         -- local variable
         Val:Int32;
      begin
         -- Get has precondition Has
         Val := MemoryStore.Get(D,Loc);
         Push_1(C,Val);
      end;
   end Load_From;


   -- storeTo <NAME>; pop the value from the top of the operand stack and stores it into memory location loc
   procedure Store_To(C:in out Calculator;D: in out MemoryStore.Database; Loc: in MemoryStore.Location_Index) is
   begin
      declare
         Val:Int32;
      begin
         Pop(C,Val);
         MemoryStore.Put(D,Loc,Val);
      end;

   end Store_To;

   -- unlock <NAME>
   procedure Unlock(C:in out Calculator;P: in String) is
   begin
      if Is_PIN(C,P) then
         C.Locked := False;
      end if;
   end Unlock;

   -- lock <NAME> The "lock" command allows updating the master PIN
   procedure Lock(C:in out Calculator;P: in String) is
   begin
      -- modify master pin if user locks with new Pin
      C.Masterpin := PIN.From_String(P);
      C.Locked := True;
   end Lock;

   -- identify the command and call corresponding operation method
   procedure Calculation(C: in out Calculator; Operation: String) is
   begin
      declare
         Val_1:Int32;
         Val_2:Int32;
         Result:Int32;
         Temp:Long_Long_Integer;
         Max_Int32: constant Int32:=Int32'Last;
         Min_Int32: constant Int32:=Int32'First;

      begin

         -- exit if locked
         --           pragma Assert (not Is_Locked(C));
         --           pragma Assert(Length(C) >= 2);
         --  --           pragma Assert(Is_Operator_Command(Operation));

         -- pop the top two values from the operand stack

         Pop(C,Val_1);
         Pop(C,Val_2);

         if Operation = "/" then
            if Val_2 = 0 then
               Push_2(C,Val_2,Val_1);
               Put_Line("ARITHMETIC_ERROR: Divide by zero");
            elsif Val_1 = Min_Int32 and Val_2 = -1 then
               Push_2(C, Val_2, Val_1);
               Put_Line("ARITHMETIC_ERROR: Division overflow");
            else
               Result := Division(Val_1, Val_2);
               Push_1(C, Result);
            end if;
            -- Division
            -- Addition
         elsif Operation = "+" then
            -- convert from Int32 to Long Long Int32
            Temp:=Long_Long_Integer(Val_1)+Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
              Temp < Long_Long_Integer(Min_Int32) then

               -- push back to operand stack
               Push_2(C,Val_1,Val_2);
               Put_Line("ARITHMETIC_ERROR: Addition overflow");
            else
                Result := Addition(Val_1,Val_2);
                Push_1(C,Result);
            end if;

            -- Subtraction
         elsif Operation = "-" then
            Temp:=Long_Long_Integer(Val_1)-Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
              Temp < Long_Long_Integer(Min_Int32) then

               -- push back to operand stack
               Push_2(C,Val_1,Val_2);
               Put_Line("ARITHMETIC_ERROR: Subtraction overflow");
            else
               Result := Subtraction(Val_1, Val_2);
               Push_1(C, Result);
            end if;


            -- Multiplication
         elsif Operation = "*" then
            declare
               IsProductZero : Boolean := (Val_1 = 0 or Val_2 = 0);
               IsProductPositive : Boolean := (Val_1 > 0 and Val_2 > 0) or (Val_1 < 0 and Val_2 < 0);
               IsProductNegative : Boolean := (Val_1 > 0 and Val_2 < 0) or (Val_1 < 0 and Val_2 > 0);
            begin
               if IsProductZero then
                  Result := 0;
                  Push_1(C, Result);
               elsif IsProductPositive then
                  if ((Val_1 > 0 and Val_2 > 0) and then Val_1 <= Max_Int32 / Val_2) then
                     Result := Multiplication(Val_1, Val_2);
                     Push_1(C, Result);
                  elsif ((Val_1 < 0 and Val_2 < 0) and then (Val_1 /= Min_Int32 and Val_2 /= Min_Int32) and then (-Val_1) <= Max_Int32 / (-Val_2)) then
                     Result := Multiplication(Val_1, Val_2);
                     Push_1(C, Result);
                  else
                     Push_2(C, Val_2, Val_1);
                     Put_Line("ARITHMETIC_ERROR: Multiplication overflow");
                  end if;
               elsif IsProductNegative then
                  if ((Val_1 >= (Min_Int32 + 1) / Val_2) and (Val_1 < 0 and Val_2 > 0))
                    or ((Val_2 >= (Min_Int32 + 1) / Val_1) and (Val_1 > 0 and Val_2 < 0)) then
                     Result := Multiplication(Val_1, Val_2);
                     Push_1(C, Result);
                  else
                     Push_2(C, Val_2, Val_1);
                     Put_Line("ARITHMETIC_ERROR: Multiplication overflow");
                  end if;
               end if;
            end;
         else
            Push_2(C, Val_2, Val_1);
         end if;
      end;
   end Calculation;


   ---------------------------------------------------------------------------
   --  Query helpers
   ---------------------------------------------------------------------------

   -- the Pin
   function Is_PIN(C : in Calculator;P: in String) return Boolean is
   begin
      -- PIN equality
      if PIN."="(PIN.From_String(P),C.Masterpin) then
         return True;
      else
         return False;
      end if;

   end Is_PIN;

   function Is_Valid_Pin (S : in String) return Boolean is
   begin
      return (S' Length = 4 and
               (for all I in S'Range => S(I) >= '0' and S(I) <= '9'));
   end Is_Valid_Pin;

   function Is_Operator_Command(S: in String) return Boolean is
   begin
      return (S = "+" or S = "-" or S = "*" or S = "/");
   end Is_Operator_Command;

   function Can_Push_N(C : in Calculator; N : Natural) return Boolean is
   begin
      return (Length(C) + N <= Calculator_Stack_Capacity);
   end Can_Push_N;

   function Is_Valid_Integer(S : String) return Boolean is
   begin
      if S'Length = 0 then
         return False;
      end if;

      for I in S'Range loop
         if I = S'First and then (S(I) = '-' or S(I) = '+') then
            null;
         elsif not (S(I) in '0' .. '9') then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Integer;








end Calculator;
