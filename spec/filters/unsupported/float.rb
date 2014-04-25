opal_filter "Float" do
  fails "Array#inspect represents a recursive element with '[...]'"
  fails "Array#to_s represents a recursive element with '[...]'"
  fails "Array#eql? returns false if any corresponding elements are not #eql?"

  # The spec uses the float "2.0" which is undistiguishable from an Integer
  fails "Range#step with exclusive end and String values raises a TypeError when passed a Float step"
  fails "Range#step with inclusive end and String values raises a TypeError when passed a Float step"
end
