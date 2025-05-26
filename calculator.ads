with PIN;
with MemoryStore;
with Interfaces;  -- supplies Int32_32 type
use Interfaces;





package Calculator with SPARK_Mode is

   type Calculator is private;
   -- If we want to change the type in the future
   -- we only need to update one place — this improves maintainability.

    -- The capacity of the calculator’s operand stack is 512.
   Calculator_Stack_Capacity : constant Positive := 512;

   --  The calculator specification allows "any 32-bit signed Int32".
   subtype Int32 is Interfaces.Integer_32;  -- range   -2_147_483_648 ..  2_147_483_647

   -- Initialises the calculator with the master pin
   -- PIN.PIN  the type PIN defined inside the package PIN
   procedure Init(C : out Calculator; Master_PIN: in String) with
     Pre=> Is_Valid_Pin(Master_PIN),
     Post=>Length(C) = 0 and Is_Locked(C) = True;


   -- push1 <NAME>
   procedure Push_1(C:in out Calculator;Number_1:in Int32) with
     Pre=>not Is_Locked(C) and Can_Push_N(C, 1),
     Post=>Length(C)=Length(C'Old)+1 and Storage(C,Length(C))=Number_1 and
     (for all I in 1..Length(C'Old)=>Storage(C,I)=Storage(C'Old,I)) and
     Is_Locked(C) = Is_Locked(C'Old);

   -- push2 <NAME> <NAME>
   procedure Push_2(C:in out Calculator;Number_1:in Int32;Number_2:in Int32) with
     Pre=> not Is_Locked(C) and Can_Push_N(C, 2),
     Post=>Length(C)=Length(C'Old)+2 and Storage(C,Length(C)-1)=Number_1
     and Storage(C,Length(C))=Number_2 and
     (for all I in 1..Length(C'Old)=>Storage(C,I)=Storage(C'Old,I)) and
     Is_Locked(C) = Is_Locked(C'Old);

   -- pop
   procedure Pop(C:in out Calculator;Result:out Int32)with
     Pre =>not Is_Locked(C) and (Length(C) /= 0),
     Post => (Length(C) = Length(C'Old)-1) and Result = Storage(C'Old,Length(C'Old)) and
     -- current size
     (for all J in 1..Length(C)=> Storage(C,J) = Storage(C'Old,J)) and
     Is_Locked(C) = Is_Locked(C'Old);
   -- with Pre => S.size /= 0); x
   -- Removes the last item from the stack S and assigns it to I;

   -- loadFrom <NAME>; loads the value stored at memory location loc and pushes it onto the operand stack
   procedure Load_From(C:in out Calculator;D : in MemoryStore.Database; Loc: in MemoryStore.Location_Index) with
     -- has space
     Pre => not Is_Locked(C) and Can_Push_N(C,1) and Loc in 1 .. MemoryStore.Max_Locations and
     MemoryStore.Has(D, Loc),
     Post =>
   -- Calculator lock state remains unchanged
     Is_Locked(C) = Is_Locked(C'Old) and
     Length(C) = Length(C'Old) + 1 and
     Storage(C, Length(C)) = MemoryStore.Get(D, Loc) and
     (for all I in 1 .. Length(C'Old) =>
          Storage(C, I) = Storage(C'Old, I));

   -- storeTo <NAME>; pop the value from the top of the operand stack and stores it into memory location loc
   procedure Store_To(C:in out Calculator;D: in out MemoryStore.Database; Loc: in MemoryStore.Location_Index) with
     -- has value
     Pre => not Is_Locked(C) and Length(C)/=0 and Loc in 1 .. MemoryStore.Max_Locations and
     not MemoryStore.Has(D, Loc),
     Post =>
   -- Calculator lock state remains unchanged
     Is_Locked(C) = Is_Locked(C'Old) and
     -- The memory location is undefined
     Length(C) = Length(C'Old) - 1 and
     (for all I in 1 .. Length(C) =>Storage(C, I) = Storage(C'Old, I));


   -- unlock <NAME>
   procedure Unlock(C:in out Calculator;P: in PIN.PIN) with
     Pre=> Is_Locked(C) and Is_PIN(C,P),
     Post=> not Is_Locked(C);

   -- lock <NAME>
   procedure Lock(C:in out Calculator;P: in String) with
     Pre=> not Is_Locked(C) and Is_Valid_Pin(P),
     Post=> Is_Locked(C);

   -- identify the command and call corresponding operation method
   procedure Calculation(C: in out Calculator; Operation: String)
     with
       Pre =>
         not Is_Locked(C) and then Length(C) >= 2 and then Is_Operator_Command(Operation),
     Post =>
       -- Pop 2 value and Push 1 result, then beside that the rest of operand stack should be remain unchanged
       ((Length(C) = Length(C'Old) - 1 and  (for all I in 1 .. Length(C'Old)-2 =>Storage(C, I) = Storage(C'Old, I))
        and Is_Locked(C) = Is_Locked(C'Old))
       -- Pop 2 value and Push 2 value, then beside that the rest of operand stack should be remain unchanged
        or (Length(C) = Length(C'Old) and  (for all I in 1 .. Length(C) =>Storage(C, I) = Storage(C'Old, I))
          and  Is_Locked(C) = Is_Locked(C'Old)));

   -- the Pin
   function Is_PIN(C : in Calculator;P: in PIN.PIN) return Boolean;

    -- "+"
   function Addition(Number_1: in Int32; Number_2: in Int32) return Int32;

   -- "-"
   function Subtraction(Number_1: in Int32; Number_2: in Int32) return Int32;

   -- "*"
   function Multiplication(Number_1: in Int32; Number_2: in Int32) return Int32;

   -- "/"
   function Division(Number_1: in Int32; Number_2: in Int32) return Int32 with
     Pre => Number_2 /= 0;



   -------already implementated in private section -------

   -- the size of operand stack
   function Length(C: in Calculator) return Natural;

   -- the status of the calculator
   function Is_Locked(C : in Calculator) return Boolean;

   -- get the master pin
   function Get_Pin(C : in Calculator) return PIN.PIN;

   function Storage(C:in Calculator ;Pos: in Integer) return Int32
   -- make function stronger
     with Ghost, Pre => (Pos in 1..Calculator_Stack_Capacity and Pos <= Length(C));



   -- check the pin is valid, later convert to PIN.PIN
   function Is_Valid_Pin(S : in String) return Boolean with
     Post =>
       Is_Valid_Pin'Result =
         (S'Length = 4 and then (for all I in S'Range => S(I) in '0' .. '9'));

   function Is_Operator_Command(S: in String) return Boolean with
     Post=>
      Is_Operator_Command'Result =  (S = "+" or S = "-" or S = "*" or S = "/");

   function Can_Push_N(C : in Calculator; N : Natural) return Boolean with
     Pre => Length(C) <= Calculator_Stack_Capacity and
     N <= Calculator_Stack_Capacity,
     Post => Can_Push_N'Result = (Length(C) + N <= Calculator_Stack_Capacity);








private
   -- calculator's operand stack; stored Int32
   type Operand_Stack_Array is array(Positive range 1..Calculator_Stack_Capacity) of Int32;
   -- the parameter
   type Calculator is record
      Length : Natural range 0..Calculator_Stack_Capacity;
      Locked: Boolean;
      Operand_stack: Operand_Stack_Array;
      Masterpin: PIN.PIN;
   end record;


   function Length(C : in Calculator) return Natural is
     (C.Length);
   function Is_Locked(C : in Calculator) return Boolean is (C.Locked);
   function Get_Pin(C : in Calculator) return PIN.PIN is
     (C.Masterpin);
   function Storage(C:in Calculator ;Pos: in Integer) return Int32 is
     -- make function stronger
      (C.Operand_stack(Pos));

end Calculator;
