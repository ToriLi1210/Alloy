with PIN;
with MemoryStore;
generic
   Calculator_Stack_Capacity : Positive;
   -- The capacity of the calculator’s operand stack is 512.

package Calculator with SPARK_Mode is

   type Calculator is private;
   -- Initialises the calculator with the master pin
   -- PIN.PIN  the type PIN defined inside the package PIN
   procedure Init   (C : out Calculator; Master_PIN: in PIN.PIN);

   -- "+"
   procedure Add(Number_1: in Integer; Number_2: in Integer;Result: out Integer);

   -- "-"
   procedure Minus(Number_1: in Integer; Number_2: in Integer;Result: out Integer);

   -- "*"
   procedure Multiple(Number_1: in Integer; Number_2: in Integer;Result: out Integer);

   -- "/"
   procedure Divide(Number_1: in Integer; Number_2: in Integer;Result: out Integer);


   -- push1 <NAME>
   procedure Push_1(C:in out Calculator;Number_1:in Integer);

   -- push2 <NAME> <NAME>
   procedure Push_2(C:in out Calculator;Number_1:in Integer;Number_2:in Integer);

   -- pop
   procedure Pop(C:in out Calculator;Result:out Integer);

   -- loadFrom <NAME>; loads the value stored at memory location loc and pushes it onto the operand stack
   procedure Load_From(C:in out Calculator;D : in out MemoryStore.Database; Loc: in MemoryStore.Location_Index);

   -- storeTo <NAME>; pop the value from the top of the operand stack and stores it into memory location loc
   procedure Store_To(C:in out Calculator;D: in out MemoryStore.Database; Loc: in MemoryStore.Location_Index);

   -- unlock <NAME>
   procedure Unlock(C:in out Calculator;P: in PIN.PIN);

   -- lock <NAME>
   procedure Lock(C:in out Calculator;P: in out PIN.PIN);

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








private
   -- calculator's operand stack; stored Integer
   type Operand_Stack_Array is array(Positive range 1..Calculator_Stack_Capacity) of Integer;
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
