import * as http from "node:http";
import * as url from "node:url";
import type { OAuth2Client } from "google-auth-library";
import { google } from "googleapis";

type Credentials = {
	clientId: string;
	clientSecret: string;
	refreshToken: string;
};

const SCOPES = [
	"https://www.googleapis.com/auth/calendar.readonly",
	"https://www.googleapis.com/auth/gmail.readonly",
	"https://www.googleapis.com/auth/tasks.readonly",
];

export async function authenticate(
	clientId: string,
	clientSecret: string,
): Promise<Credentials> {
	const oauth2Client = new google.auth.OAuth2(
		clientId,
		clientSecret,
		"http://localhost:3000/oauth2callback",
	);

	const authUrl = oauth2Client.generateAuthUrl({
		access_type: "offline",
		scope: SCOPES,
	});

	console.log("Authorize this app by visiting:\n", authUrl);

	const code = await getAuthCode();
	const { tokens } = await oauth2Client.getToken(code);

	return {
		clientId,
		clientSecret,
		refreshToken: tokens.refresh_token || "",
	};
}

function getAuthCode(): Promise<string> {
	return new Promise((resolve, reject) => {
		const server = http.createServer((req, res) => {
			if (req.url?.startsWith("/oauth2callback")) {
				const query = url.parse(req.url, true).query;
				const code = query.code as string;

				res.writeHead(200, { "Content-Type": "text/html" });
				res.end(
					"<h1>Authentication successful!</h1><p>You can close this window.</p>",
				);

				server.close();
				resolve(code);
			}
		});

		server.listen(3000, () => {
			console.log("Waiting for authentication...");
		});

		server.on("error", reject);
	});
}
