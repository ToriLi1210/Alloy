with Ada.Text_IO;
use Ada.Text_IO;
with MemoryStore;
with Interfaces;
use Interfaces;

package body Calculator is
   ---------------------------------------------------------------------------
   --  Initialisation
   ---------------------------------------------------------------------------
   procedure Init(C : out Calculator; Master_PIN: in PIN.PIN) is
   begin
      -- The calculator begins in the locked state.
      C.Locked:=True;
      -- User needs to supply master pin
      C.Masterpin:=Master_PIN;
      -- The size of operand stack is 0
      C.Length:=0;
      C.Operand_stack:=(others=>0);

   end Init;

   -- "+"
   procedure Addition(Number_1: in Int32; Number_2: in Int32;Result: out Int32) is
   begin
      Result:= Number_1+Number_2;
   end Addition;

   -- "-"
   procedure Subtraction(Number_1: in Int32; Number_2: in Int32;Result: out Int32) is
   begin
      Result:= Number_1-Number_2;

   end Subtraction;

   -- "*"
   procedure Multiplication(Number_1: in Int32; Number_2: in Int32;Result: out Int32) is
   begin
      Result:= Number_1*Number_2;
   end Multiplication;

   -- "/"
   procedure Division(Number_1: in Int32; Number_2: in Int32;Result: out Int32) is
   begin
      Result:= Number_1/Number_2;
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
   procedure Load_From(C:in out Calculator;D : in out MemoryStore.Database; Loc: in MemoryStore.Location_Index) is
   begin
      declare
         -- local variable
         Val:Int32;
      begin
         -- the value exist at memory location
         if MemoryStore.Has(D,Loc) then
            Val := MemoryStore.Get(D,Loc);
            Push_1(C,Val);
         else
            Put_Line("No value has been stored in memory location");
         end if;
      end;
   end Load_From;


   -- storeTo <NAME>; pop the value from the top of the operand stack and stores it into memory location loc
   procedure Store_To(C:in out Calculator;D: in out MemoryStore.Database; Loc: in MemoryStore.Location_Index) is
   begin
      declare
         Val:Int32;
      begin
         -- no value exist at memory location
         if not MemoryStore.Has(D,Loc) then
            Pop(C,Val);
            MemoryStore.Put(D,Loc,Val);
         else
            Put_Line("A value has already been stored in memory location");
         end if;
      end;

   end Store_To;


   -- unlock <NAME>
   procedure Unlock(C:in out Calculator;P: in PIN.PIN) is
   begin
      -- unlock if pin is correct
      if Is_PIN(C,P) then
         C.Locked := False;
      else
         Put_Line("Invalid Pin");
      end if;

   end Unlock;

   -- lock <NAME> The “lock” command allows updating the master PIN
   procedure Lock(C:in out Calculator;P: in PIN.PIN) is
   begin
      -- modify master pin if user locks with new Pin
      C.Masterpin := P;
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
         pragma Assert (not Is_Locked(C));

         -- pop the top two values from the operand stack
         Pop(C,Val_1);
         Pop(C,Val_2);

         -- Addition
         if Operation = "+" then
            -- convert from Int32 to Long Long Int32
            Temp:=Long_Long_Integer(Val_1)+Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
                  Temp < Long_Long_Integer(Min_Int32) then

                   -- push back to operand stack
                   Push_2(C,Val_1,Val_2);
                Put_Line("Invald operation: Addition overflow");
            else
                Addition(Val_1,Val_2,Result);
                Push_1(C,Result);
            end if;

         -- Subtraction
         elsif Operation = "-" then
            -- convert from Int32 to Long Long Int32
            Temp:=Long_Long_Integer(Val_1)-Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
                  Temp < Long_Long_Integer(Min_Int32) then

                   -- push back to operand stack
                   Push_2(C,Val_1,Val_2);
                Put_Line("Invald operation: Subtraction overflow");
            else
                Subtraction(Val_1,Val_2,Result);
                Push_1(C,Result);
            end if;

         -- Multiplication
         elsif Operation = "*" then
            -- convert from Int32 to Long Long Int32
            Temp:=Long_Long_Integer(Val_1)*Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
                  Temp < Long_Long_Integer(Min_Int32) then

                   -- push back to operand stack
                   Push_2(C,Val_1,Val_2);
                Put_Line("Invald operation: Multiplication overflow");
            else
                Multiplication(Val_1,Val_2,Result);
                Push_1(C,Result);
            end if;

         -- Division
         elsif Operation = "/" then
                   -- convert from Int32 to Long Long Int32
            Temp:=Long_Long_Integer(Val_1)/Long_Long_Integer(Val_2);

            -- ensure the result not overflow
            if Temp > Long_Long_Integer(Max_Int32) or
                  Temp < Long_Long_Integer(Min_Int32) then

                   -- push back to operand stack
                   Push_2(C,Val_1,Val_2);
                Put_Line("Invald operation: Multiplication overflow");
            else
                Division(Val_1,Val_2,Result);
                Push_1(C,Result);
            end if;
         end if;
      end;


   end Calculation;


   ---------------------------------------------------------------------------
   --  Query helpers
   ---------------------------------------------------------------------------

   -- the Pin
   function Is_PIN(C : in Calculator;P: in PIN.PIN) return Boolean is
   begin
      -- PIN equality
      if PIN."="(P,C.Masterpin) then
         return True;
      else
         return False;
      end if;

   end Is_PIN;

   function Is_Valid_Pin (S : in String) return Boolean is
   begin

      return (S'Length = 4 and then
      (for all I in S'Range => S(I) in '0' .. '9'));
   end Is_Valid_Pin;

   function Is_Operator_Command(S: in String) return Boolean is
   begin
      return (S = "+" or S = "-" or S = "*" or S = "/");
   end Is_Operator_Command;






end Calculator;
