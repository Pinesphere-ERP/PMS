import urllib.request, json
req = urllib.request.Request('http://127.0.0.1:8000/api/v1/payments/razorpay/verify', method='POST', data=json.dumps({'razorpay_order_id': 'test', 'razorpay_payment_id': 'test', 'razorpay_signature': 'test', 'amount': 100}).encode(), headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as response:
        print(response.status, response.read().decode())
except urllib.error.HTTPError as e:
    print(e.code, e.read().decode())