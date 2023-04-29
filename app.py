from flask import Flask, request
from datetime import datetime

app = Flask(__name__)

class parkingAPI:
    ticketId = 1
    parkedCarsInfo = {}

    @app.route('/entry', methods=['POST'])
    def entry():
        plate = request.args.get('plate')
        parkingLot = request.args.get('parkingLot')
        parkingAPI.parkedCarsInfo[parkingAPI.ticketId] = (plate, parkingLot, datetime.now())
        lastTicketId = parkingAPI.ticketId
        parkingAPI.ticketId += 1

        #return f"your ticket ID is: {lastTicketId}. Enjoy!"
        return parkingAPI.parkedCarsInfo[parkingAPI.ticketId]

    @app.route('/exit', methods=['POST'])
    def exit():
        requestedTicketId = int(request.args.get('ticketId'))
        if requestedTicketId not in parkingAPI.parkedCarsInfo:
            return f"Ticket ID {requestedTicketId} is not found!"
        
        carInfo = parkingAPI.parkedCarsInfo[requestedTicketId]
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