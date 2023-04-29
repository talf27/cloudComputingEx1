from flask import Flask, request
from datetime import datetime

app = Flask(__name__)

class parkingAPI:
    ticketId = 1
    parkedCarsInfo = {}

    @app.route('/entry', methods=['GET', 'POST'])
    def entry():
        plate = request.form.get('plate')
        parkingLot = request.form.get('parkingLot')
        parkingAPI.parkedCarsInfo[parkingAPI.ticketId] = (plate, parkingLot, datetime.now())
        lastTicketId = parkingAPI.ticketId
        parkingAPI.ticketId += 1

        return f"your ticket ID is: {lastTicketId}. Enjoy!"

    @app.route('/exit', methods=['GET', 'POST'])
    def exit():
        requestedTicketId = int(request.form.get('ticketId'))
        if requestedTicketId not in parkingAPI.parkedCarsInfo:
            return f"Ticket ID {requestedTicketId} is not found!"
        
        carInfo = parkingAPI.parkedCarsInfo[requestedTicketId]
        del parkingAPI.parkedCarsInfo[requestedTicketId]
        totalHours = (datetime.now() - carInfo[2]).total_seconds() / 3600
        if totalHours - int(totalHours) < 0.25:
            totalHours = int(totalHours)
        else:
            totalHours = int(totalHours) + 1
        
        return f"""License plate: {carInfo[0]}
        total parked time: {totalHours} hours
        parking lot ID: {carInfo[1]}
        total charge: {totalHours * 10}$
        Thank you :)"""