function requestToken() { 
    $.ajax({
           type: 'POST',
           crossDomain: true,
           async: false, // MÅ HA DENNE MED
           url: 'https://accounts.accesscontrol.windows.net/77da4c42-ba77-462b-bb54-7f7ea57bd0a8/tokens/OAuth/2', //https://shielded-falls-20297.herokuapp.com/
           headers: {
             "content-type": "application/x-www-form-urlencoded"
           },
           data: {
               "grant_type": "client_credentials",
               //"redirect_uri": "https://varenergi.sharepoint.com/sites/VarinCommon",
               "client_id": "cc16a852-30a1-49fc-af11-ced5a79451f1@77da4c42-ba77-462b-bb54-7f7ea57bd0a8",
               "client_secret": "rlCAGZ+TDegPptleV+eM7jmM9EKtjqkUNL29YJKrnuI=",
               "resource": "00000003-0000-0ff1-ce00-000000000000/varenergi.sharepoint.com@77da4c42-ba77-462b-bb54-7f7ea57bd0a8"
               //"code": "PAQABAAEAAAD--DLA3VO7QrddgJg7WevrEqC4YFAFZfeJ6jwPbRKBn1FzWKz5bKa0YF-Ndvnd4pafhSe3pqJ5dL5_1m2K7rdF8-34pBirJZULjZbSKWhDVe0fybb_T6lVygLrOPgzomTSuF0Fpd7B32uwZXJYeMpl-OQl0jkFxFg57poCSH3YXRM2IHhqgGwGJo43ZUUE8DKsj3IDCqTwQe41MyDw--rhr1f4brMmq66qX7-gLYHPVuNjusnvqVC0XfHUBqHdqmgaXLtUW54Nle3RqEMRdL40jpf5zfchRGRodr3jijo4jCAA"
           },
           success: function(Responsedata) {
               testAccessToken = Responsedata.access_token;
               console.log(testAccessToken)
           },
           error: function(Responsedata, errorThrown, status) {
             console.log("working2");
             console.log(Responsedata);
           }
    });
}

requestToken();