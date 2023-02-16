#! /bin/bash
#Set up the PSQL variable for querying the salon database
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

EXIT() {
  echo -e "\nThank you for your preference!\n"
}

APPOINTMENT(){
  CUSTOMER_PHONE=$1 CUSTOMER_ID=$2 CUSTOMER_NAME=$3 SERVICE_ID_SELECTED=$4
  #Query the name of the service the customer selected and format it
  SERVICE_NAME_RAW=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  SERVICE_NAME=$(echo $SERVICE_NAME_RAW | sed 's/^ * *$//')

  #Book the appointment and update the database
  echo -e "At which time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  echo -e "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

CUSTOMER_CHECK(){
echo -e "\nWhat is your phone number?"
read CUSTOMER_PHONE

#Check if the customer already exists
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
if [[ -z $CUSTOMER_ID ]]
  then
    #Create new customer record and insert it in the database
    echo -e "\nIt seems this is your first time with us. May I ask your name?"
    read CUSTOMER_NAME
    while [[ "$CUSTOMER_NAME" != [a-zA-Z]* ]]
      do
        echo -e "\nInvalid data. Please insert your name using only letters and spaces:"
        read CUSTOMER_NAME
    done
    INSERT_NEW_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    echo -e "\nPleased to meet you, $CUSTOMER_NAME!"
    #Redirect to the appointment booking
  else
    #Customer already exists
    CUSTOMER_NAME_RAW=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
    CUSTOMER_NAME=$(echo $CUSTOMER_NAME_RAW | sed 's/^ * *$//')
    echo -e "\nWelcome back, $CUSTOMER_NAME!"
    #Redirect to the appointment booking
fi
APPOINTMENT "$CUSTOMER_PHONE" "$CUSTOMER_ID" "$CUSTOMER_NAME" "$SERVICE_ID_SELECTED"
}

SERVICES() {
#Query the list of available services
if [[ ! -z $1 ]]
  then
    echo -e "\n$1"
fi
SERVICES_LIST=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
SERVICES_COUNT=$($PSQL "SELECT COUNT(service_id) FROM services")
echo -e "How may we help you today?"

#display service list
echo "$SERVICES_LIST" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

#Read the user's selection
read SERVICE_ID_SELECTED
if [[ $SERVICE_ID_SELECTED =~ ^[1-9]$ && $SERVICE_ID_SELECTED -le $SERVICES_COUNT ]]
  then
    CUSTOMER_CHECK $SERVICE_ID_SELECTED
  else 
    SERVICES "I'm sorry, but that's not a valid option. Please, try again."
  fi
}

echo -e "\nHello and welcome to White's Hair Salon!"
SERVICES