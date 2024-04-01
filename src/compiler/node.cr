module Lucid::Compiler
  abstract class Node
    property loc : Location

    def initialize
      @loc = Location[0, 0]
    end

    def at(@loc : Location) : self
      self
    end

    abstract def to_s(io : IO) : Nil
    abstract def inspect(io : IO) : Nil
  end

  abstract class Statement < Node
  end

  abstract class Expression < Node
  end

  class ExpressionStatement < Statement
    property value : Expression

    def initialize(@value : Expression)
      super()
    end

    def to_s(io : IO) : Nil
      io << '('
      @value.to_s io
      io << ')'
    end

    def inspect(io : IO) : Nil
      io << "ExpressionStatement("
      @value.inspect io
      io << ')'
    end
  end

  class Path < Expression
    property names : Array(Ident)
    property? global : Bool

    def initialize(@names : Array(Ident), @global : Bool)
      super()
    end

    def to_s(io : IO) : Nil
      @names.each do |name|
        case name
        in Const
          io << "::" if name.global?
          io << name
        in Ident
          io << "::" if name.global?
          io << '.' << name
        end
      end
    end

    def inspect(io : IO) : Nil
      io << "Path(names: "
      io << @names << ", global: "
      io << @global << ')'
    end
  end

  class Ident < Expression
    property value : String
    property? global : Bool

    def initialize(@value : String, @global : Bool)
      super()
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "Ident(value: "
      @value.inspect io
      io << ", global: "
      io << @global << ')'
    end
  end

  class Const < Ident
    def inspect(io : IO) : Nil
      io << "Const(value: "
      @value.inspect io
      io << ", global: "
      io << @global << ')'
    end
  end

  class Var < Expression
    property name : Node
    property type : Node?
    property value : Node?

    def initialize(@name : Node, @type : Node?, @value : Node?)
      super()
    end

    def uninitialized? : Bool
      @value.nil?
    end

    def to_s(io : IO) : Nil
      io << @name
      if @type
        io << " : " << @type
      end

      if @value
        io << " = " << @value
      end
    end

    def inspect(io : IO) : Nil
      io << "Var(name: "
      @name.inspect io
      io << ", type: "
      @type.inspect io
      io << ", value: "
      @value.inspect io
      io << ')'
    end
  end

  class InstanceVar < Var
  end

  class ClassVar < Var
  end

  class Prefix < Expression
    enum Operator
      Plus        # +
      Minus       # -
      Splat       # *
      DoubleSplat # **

      def self.from(kind : Token::Kind)
        case kind
        when .plus?        then Plus
        when .minus?       then Minus
        when .star?        then Splat
        when .double_star? then DoubleSplat
        else
          raise "invalid prefix operator '#{kind}'"
        end
      end

      def to_s : String
        case self
        in Plus        then "+"
        in Minus       then "-"
        in Splat       then "*"
        in DoubleSplat then "**"
        end
      end
    end

    property op : Operator
    property value : Node

    def initialize(@op : Operator, @value : Node)
      super()
    end

    def to_s(io : IO) : Nil
      io << @op << @value
    end

    def inspect(io : IO) : Nil
      io << "Prefix(op: '" << @op
      io << "', value: "
      @value.inspect io
      io << ')'
    end
  end

  class Infix < Expression
    enum Operator
      Add      # +
      Subtract # -
      Multiply # *
      Divide   # /
      DivFloor # //
      Power    # **

      def self.from(kind : Token::Kind)
        case kind
        when .plus?         then Add
        when .minus?        then Subtract
        when .star?         then Multiply
        when .slash?        then Divide
        when .double_slash? then DivFloor
        when .double_star?  then Power
        else
          raise "invalid infix operator '#{kind}'"
        end
      end

      def to_s : String
        case self
        in Add      then "+"
        in Subtract then "-"
        in Multiply then "*"
        in Divide   then "/"
        in DivFloor then "//"
        in Power    then "**"
        end
      end
    end

    property op : Operator
    property left : Node
    property right : Node

    def initialize(@op : Operator, @left : Node, @right : Node)
      super()
    end

    def to_s(io : IO) : Nil
      io << @left << ' ' << @op << ' ' << @right
    end

    def inspect(io : IO) : Nil
      io << "Infix(left: "
      @left.inspect io
      io << ", op: "
      @op.inspect io
      io << ", right: "
      @right.inspect io
      io << ')'
    end
  end

  class Assign < Expression
    property target : Node
    property value : Node

    def initialize(@target : Node, @value : Node)
      super()
    end

    def to_s(io : IO) : Nil
      io << @target << " = " << @value
    end

    def inspect(io : IO) : Nil
      io << "Assign(target: "
      @target.inspect io
      io << ", value: "
      @value.inspect io
      io << ')'
    end
  end

  class Call < Expression
    property receiver : Node
    property args : Array(Node)

    def initialize(@receiver : Node, @args : Array(Node))
      super()
    end

    def to_s(io : IO) : Nil
      io << @receiver << '('
      @args.join(io, ", ") unless @args.empty?
      io << ')'
    end

    def inspect(io : IO) : Nil
      io << "Call(receiver: "
      @receiver.inspect io
      io << ", args: "
      @args.inspect io
      io << ')'
    end
  end

  class StringLiteral < Expression
    property value : String

    def initialize(@value : String)
      super()
    end

    def to_s(io : IO) : Nil
      @value.inspect io
    end

    def inspect(io : IO) : Nil
      io << "StringLiteral("
      @value.inspect io
      io << ')'
    end
  end

  class IntLiteral < Expression
    property raw : String
    property value : Int64

    def initialize(@raw : String)
      super()
      @value = @raw.to_i64 strict: false
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "IntLiteral("
      @value.inspect io
      io << ')'
    end
  end

  class FloatLiteral < Expression
    property raw : String
    property value : Float64

    def initialize(@raw : String)
      super()
      @value = @raw.to_f64 strict: false
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "FloatLiteral("
      @value.inspect io
      io << ')'
    end
  end

  class BoolLiteral < Expression
    # ameba:disable Naming/QueryBoolMethods
    property value : Bool

    def initialize(@value : Bool)
      super()
    end

    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "BoolLiteral(" << @value << ')'
    end
  end

  class NilLiteral < Expression
    def to_s(io : IO) : Nil
      io << "nil"
    end

    def inspect(io : IO) : Nil
      io << "NilLiteral"
    end
  end
end
