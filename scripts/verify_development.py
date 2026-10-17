#!/usr/bin/env python3
"""Verify real local Portal login and API routing without printing credentials."""
from html import unescape
from html.parser import HTMLParser
from http.cookiejar import CookieJar
import json
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import HTTPCookieProcessor, Request, build_opener

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local-development"


class Fields(HTMLParser):
    def __init__(self):
        super().__init__()
        self.values = {}

    def handle_starttag(self, tag, attributes):
        values = dict(attributes)
        if tag == "input" and values.get("type") == "hidden" and "name" in values:
            self.values[values["name"]] = values.get("value", "")


def main():
    credentials = json.loads((LOCAL / "settings.json").read_text())
    browser = build_opener(HTTPCookieProcessor(CookieJar()))
    url = "http://127.0.0.1:52219/login.aspx"
    with browser.open(url, timeout=60) as response:
        body = response.read().decode("utf-8")
    assert "txtPassword" in body, "Login form did not render"
    fields = Fields()
    fields.feed(body)
    fields.values.update({"ddlAccountKind": "employee", "txtUserName": credentials["admin_username"],
                          "txtPassword": credentials["admin_password"] + "-wrong", "btnLogin": "تسجيل الدخول"})
    with browser.open(Request(url, data=urlencode(fields.values).encode()), timeout=60) as response:
        rejected = response.read().decode("utf-8")
        assert response.url.lower().endswith("login.aspx"), "Wrong password was accepted"
        assert "غير صحيحة" in unescape(rejected), "Wrong-password response was not the expected authentication failure"
    fields = Fields()
    fields.feed(rejected)
    fields.values.update({"ddlAccountKind": "employee", "txtUserName": credentials["admin_username"],
                          "txtPassword": credentials["admin_password"], "btnLogin": "تسجيل الدخول"})
    with browser.open(Request(url, data=urlencode(fields.values).encode()), timeout=60) as response:
        body = response.read().decode("utf-8")
        final_url = response.url
    (LOCAL / "verified-dashboard.html").write_text(body)
    assert "Brands_Dashboards.aspx" in final_url, "Login did not redirect to the dashboard"
    assert "علامة تجريبية" in unescape(body), "Seeded development brand did not render"
    print("PASS: login form, wrong-password rejection, administrator authentication, session cookie, dashboard and database-backed brand.")
    with browser.open("http://127.0.0.1:3001/", timeout=60) as response:
        assert response.status == 200
    try:
        browser.open(Request("http://127.0.0.1:3001/api/Users/Login", data=b"{}",
                             headers={"Content-Type": "application/json"}), timeout=30)
    except HTTPError as error:
        assert error.code == 400, "Unexpected API validation response"
        assert b"INVALID_REQUEST" in error.read(), "API route did not return its validation envelope"
    else:
        raise AssertionError("API unexpectedly accepted an invalid login request")
    print("PASS: API startup, attribute routing and input validation.")
    login = {"Username": credentials["admin_username"], "Password": credentials["admin_password"],
             "AppVersion": "local-verification", "Device": {"DeviceID": "prosto-local-verification",
             "Platform": "Android", "Model": "Local development test", "OSVersion": "local"}}
    with browser.open(Request("http://127.0.0.1:3001/api/Users/Login", data=json.dumps(login).encode(),
                              headers={"Content-Type": "application/json"}), timeout=60) as response:
        payload = json.load(response)
    assert payload["Success"] and payload["Data"]["User"]["UserName"] == credentials["admin_username"]
    bearer = {"Authorization": "Bearer " + payload["Data"]["AccessToken"]}
    with browser.open(Request("http://127.0.0.1:3001/api/Get_InfoPages", headers=bearer), timeout=60) as response:
        assert json.load(response)["Success"]
    with browser.open(Request("http://127.0.0.1:3001/api/Logout", data=b"", headers=bearer), timeout=30) as response:
        assert json.load(response)["Success"]
    try:
        browser.open(Request("http://127.0.0.1:3001/api/Get_InfoPages", headers=bearer), timeout=30)
    except HTTPError as error:
        assert error.code == 401
    else:
        raise AssertionError("API accepted a logged-out token")
    print("PASS: API password login, bearer session, information pages, logout and revoked-token rejection.")
    from setup_development import sql, DATABASE
    result = sql("""SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Inserted TABLE(NewID decimal(38,0));
INSERT @Inserted EXEC dbo.Insert_Brands @Title_Ar=N'Local verification',@Title_En=N'Local verification',@AddedUser=1;
DECLARE @ID int=(SELECT CONVERT(int,NewID) FROM @Inserted);
IF @ID IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@ID AND IsActive=1 AND IsDeleted=0)
 THROW 51000, 'Brand insert verification failed.', 1;
EXEC dbo.Update_Brands_IsActive_ByID @ID=@ID,@IsActive=0,@ModifyUser=1;
IF NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@ID AND IsActive=0) THROW 51000, 'Brand update verification failed.', 1;
ROLLBACK;
SELECT 'CRUD_TEST_PASSED';
""", DATABASE)
    assert "CRUD_TEST_PASSED" in result.stdout
    print("PASS: database-backed brand insert/update with rollback.")


if __name__ == "__main__":
    main()
