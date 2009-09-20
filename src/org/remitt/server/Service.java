/*
 * $Id$
 *
 * Authors:
 *      Jeff Buchbinder <jeff@freemedsoftware.org>
 *
 * REMITT Electronic Medical Information Translation and Transmission
 * Copyright (C) 1999-2009 FreeMED Software Foundation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

package org.remitt.server;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.annotation.Resource;
import javax.jws.WebParam;
import javax.jws.WebService;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.xml.ws.WebServiceContext;

import org.apache.log4j.Logger;

@WebService(endpointInterface = "org.remitt.server.IServiceInterface", serviceName = "remittService")
public class Service implements IServiceInterface {
	@Resource
	WebServiceContext context;

	static final Logger log = Logger.getLogger(Service.class);

	@GET
	@Path("protocolversion")
	@Produces("application/json")
	public String getProtocolVersion() {
		return "2.0";
	}

	@POST
	@Path("changepassword/{pw}")
	@Produces("application/json")
	public Boolean changePassword(
			@PathParam("pw") @WebParam(name = "pw") String newPassword) {
		Connection c = getConnection();

		String userName = getCurrentUserName();

		PreparedStatement cStmt = null;
		try {
			cStmt = c
					.prepareCall("UPDATE tUser SET passhash = MD5( ? ) WHERE username = ?;");

			cStmt.setString(1, newPassword);
			cStmt.setString(2, userName);

			@SuppressWarnings("unused")
			boolean hadResults = cStmt.execute();

			return (cStmt.getUpdateCount() == 1);
		} catch (NullPointerException npe) {
			log.error("Caught NullPointerException", npe);
			return false;
		} catch (SQLException e) {
			log.error("Caught SQLException", e);
			return false;
		}
	}

	@GET
	@Path("username")
	@Produces("application/json")
	public String getCurrentUserName() {
		return context.getUserPrincipal().getName();
	}

	@POST
	@Path("submit")
	@Produces("application/json")
	public Integer insertPayload(
			@PathParam("inputPayload") @WebParam(name = "inputPayload") String inputPayload,
			@PathParam("renderPlugin") @WebParam(name = "renderPlugin") String renderPlugin,
			@PathParam("renderOption") @WebParam(name = "renderOption") String renderOption,
			@PathParam("transportPlugin") @WebParam(name = "transportPlugin") String transportPlugin,
			@PathParam("transportOption") @WebParam(name = "transportOption") String transportOption) {
		Connection c = getConnection();

		String userName = getCurrentUserName();

		log.debug("Submit job for " + userName + " [payload length = "
				+ inputPayload.length() + "]");

		PreparedStatement cStmt = null;
		try {
			cStmt = c.prepareStatement("INSERT INTO tPayload ( "
					+ "user, payload, renderPlugin, renderOption, "
					+ "transportPlugin, transportOption "
					+ " ) VALUES ( ?, ?, ?, ?, ?, ? );",
					PreparedStatement.RETURN_GENERATED_KEYS);

			cStmt.setString(1, userName);
			cStmt.setString(2, inputPayload);
			cStmt.setString(3, renderPlugin);
			cStmt.setString(4, renderOption);
			cStmt.setString(5, transportPlugin);
			cStmt.setString(6, transportOption);

			@SuppressWarnings("unused")
			boolean hadResults = cStmt.execute();
			ResultSet newKey = cStmt.getGeneratedKeys();
			return newKey.getInt("id");
		} catch (NullPointerException npe) {
			log.error("Caught NullPointerException", npe);
			return null;
		} catch (SQLException e) {
			log.error("Caught SQLException", e);
			return null;
		}
	}

	@POST
	@Path("setoption/{namespace}/{option}/{value}")
	@Produces("application/json")
	public Boolean setConfigValue(
			@PathParam("namespace") @WebParam(name = "namespace") String namespace,
			@PathParam("option") @WebParam(name = "option") String option,
			@PathParam("value") @WebParam(name = "value") String value) {
		String userName = getCurrentUserName();
		try {
			Configuration.setConfigValue(userName, namespace, option, value);
		} catch (Exception ex) {
			log.error(ex);
			return Boolean.FALSE;
		}
		return Boolean.TRUE;
	}

	@POST
	@Path("getstatus/{jobid}")
	@Produces("application/json")
	public Integer getStatus(
			@PathParam("jobid") @WebParam(name = "jobid") Integer jobId) {
		String userName = getCurrentUserName();

		Connection c = getConnection();

		CallableStatement cStmt = null;
		try {
			cStmt = c.prepareCall("{ CALL p_GetStatus( ?, ? ); }");
			cStmt.setString(1, userName);
			cStmt.setInt(2, jobId);

			boolean hadResults = cStmt.execute();
			if (hadResults) {
				ResultSet r = cStmt.getResultSet();
				String status = r.getString("status");
				String stage = r.getString("stage");

				if (status.equalsIgnoreCase("incomplete")) {
					if (status.equalsIgnoreCase("validation")) {
						return 1; // validation
					} else if (status.equalsIgnoreCase("render")) {
						return 2; // render
					} else if (status.equalsIgnoreCase("translation")) {
						return 3; // translation
					} else if (status.equalsIgnoreCase("transmission")) {
						return 4; // transmission/transport
					}
				} else {
					return 0; // completed
				}
			}

			return 5; // unknown
		} catch (NullPointerException npe) {
			log.error("Caught NullPointerException", npe);
			return null;
		} catch (SQLException e) {
			log.error("Caught SQLException", e);
			return null;
		}
	}

	/**
	 * Internal method to get a database connection.
	 * 
	 * @return
	 */
	protected Connection getConnection() {
		// Connection c = (Connection) Configuration.getServletContext()
		// .getServletContext().getAttribute("connection");
		// return c;
		return Configuration.getConnection();
	}

}
