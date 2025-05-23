with PIN;
with MemoryStore;
with Interfaces;  -- supplies Int32_32 type



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
   procedure Init   (C : out Calculator; Master_PIN: in PIN.PIN);

   -- "+"
   procedure Addition(Number_1: in Int32; Number_2: in Int32;Result: out Int32);

   -- "-"
   procedure Subtraction(Number_1: in Int32; Number_2: in Int32;Result: out Int32);

   -- "*"
   procedure Multiplication(Number_1: in Int32; Number_2: in Int32;Result: out Int32);

   -- "/"
   procedure Division(Number_1: in Int32; Number_2: in Int32;Result: out Int32);


   -- push1 <NAME>
   procedure Push_1(C:in out Calculator;Number_1:in Int32);

   -- push2 <NAME> <NAME>
   procedure Push_2(C:in out Calculator;Number_1:in Int32;Number_2:in Int32);

   -- pop
   procedure Pop(C:in out Calculator;Result:out Int32);

   -- loadFrom <NAME>; loads the value stored at memory location loc and pushes it onto the operand stack
   procedure Load_From(C:in out Calculator;D : in out MemoryStore.Database; Loc: in MemoryStore.Location_Index);

   -- storeTo <NAME>; pop the value from the top of the operand stack and stores it into memory location loc
   procedure Store_To(C:in out Calculator;D: in out MemoryStore.Database; Loc: in MemoryStore.Location_Index);

   -- unlock <NAME>
   procedure Unlock(C:in out Calculator;P: in PIN.PIN);

   -- lock <NAME>
   procedure Lock(C:in out Calculator;P: in PIN.PIN);

   -- identify the command and call corresponding operation method
   procedure Calculation(C: in out Calculator; Operation: String);

   -- the Pin
   function Is_PIN(C : in Calculator;P: in PIN.PIN) return Boolean;


   -------already implementated in private section -------

   -- the size of operand stack
   function Length(C: in Calculator) return Natural;

   -- the status of the calculator
   function Is_Locked(C : in Calculator) return Boolean;

   -- get the master pin
   function Get_Pin(C : in Calculator) return PIN.PIN;

    -- check the pin is valid, later convert to PIN.PIN
   function Is_Valid_Pin(S : in String) return Boolean;

   function Is_Operator_Command(S: in String) return Boolean;








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

end Calculator;
