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
      Result : Long_Long_Integer;
   begin
      Result := Long_Long_Integer(Number_1) + Long_Long_Integer(Number_2);
      if Result < Long_Long_Integer(Int32'First) then
         return Int32'First;
      elsif Result > Long_Long_Integer(Int32'Last) then
         return Int32'Last;
      else
         return Int32(Result);
      end if;
   end Addition;

   -- "-"
   function Subtraction(Number_1: in Int32; Number_2: in Int32) return Int32 is
      Result : Long_Long_Integer;
   begin
      Result := Long_Long_Integer(Number_1) - Long_Long_Integer(Number_2);
      if Result < Long_Long_Integer(Int32'First) then
         return Int32'First;
      elsif Result > Long_Long_Integer(Int32'Last) then
         return Int32'Last;
      else
         return Int32(Result);
      end if;
   end Subtraction;

   -- "*"
   function Multiplication(Number_1: in Int32; Number_2: in Int32) return Int32 is
      Result : Long_Long_Integer;
   begin
      Result := Long_Long_Integer(Number_1) * Long_Long_Integer(Number_2);
      if Result < Long_Long_Integer(Int32'First) then
         return Int32'First;
      elsif Result > Long_Long_Integer(Int32'Last) then
         return Int32'Last;
      else
         return Int32(Result);
      end if;
   end Multiplication;

   -- "/"
   function Division(Number_1: in Int32; Number_2: in Int32) return Int32 is
   begin
      if Number_1 = Int32'First and Number_2 = -1 then
         return Int32'Last;
      else
         return Number_1 / Number_2;
      end if;
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
   procedure Unlock(C:in out Calculator;P: in PIN.PIN) is
   begin
      if Is_PIN(C,P) then
         C.Locked := False;
      end if;
   end Unlock;

   -- lock <NAME> The “lock” command allows updating the master PIN
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

      begin

         -- exit if locked
         pragma Assert (not Is_Locked(C));
         pragma Assert(Length(C) >= 2);
         pragma Assert(Operation = "+" or Operation = "-" or Operation = "*" or Operation = "/");

         -- pop the top two values from the operand stack

         Pop(C,Val_1);
         Pop(C,Val_2);

         -- Addition
         if Operation = "+" then
            Result := Addition(Val_1, Val_2);
            Push_1(C, Result);

            -- Subtraction
         elsif Operation = "-" then
            Result := Subtraction(Val_1, Val_2);
            Push_1(C, Result);

            -- Multiplication
         elsif Operation = "*" then
            Result := Multiplication(Val_1, Val_2);
            Push_1(C, Result);

            -- Division
         elsif Operation = "/" then
            Result := Division(Val_1, Val_2);
            Push_1(C, Result);


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








end Calculator;
