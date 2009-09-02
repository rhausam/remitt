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

package org.remitt.prototype;

import org.remitt.prototype.ProcessorThread.ThreadType;

public class JobThreadState {
	private Integer threadId = 0;
	private Integer processorId = 0;
	private ProcessorThread.ThreadType threadType = null;
	private String plugin = "";

	public JobThreadState() {
	}

	public void setThreadId(Integer tId) {
		threadId = tId;
	}

	public Integer getThreadId() {
		return threadId;
	}

	public void setProcessorId(Integer pId) {
		processorId = pId;
	}

	public Integer getProcessorId() {
		return processorId;
	}

	public void setThreadType(ThreadType t) {
		threadType = t;
	}

	public ThreadType getThreadType() {
		return threadType;
	}

	public void setPlugin(String p) {
		plugin = p;
	}

	public String getPlugin() {
		return plugin;
	}
}