######################################
# ResultMessages
####################################

Function ExistsBut($Type, $valueChecked, $ValueReturned )
{
  return "$Type : $valueChecked exists, but with value $ValueReturned"
}

Function ExistsNot($Type, $valueChecked )
{
    return "$Type : $valueChecked doesn't exists"
}

Function ExistsCorrect($Type, $valueChecked, $ValueReturned )
{
  return "$Type : $valueChecked exists, with correct value $ValueReturned"
}