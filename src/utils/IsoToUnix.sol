pragma solidity ^0.8.24;

import "./Strings.sol";
import "./StringUtils.sol";

// modifed contract of https://github.com/SkeletonCodeworks/DateUtils
library IsoToUnix {
    using strings for *;
    using StringUtils for *;

    uint256 constant SECONDS_IN_MINUTE = 60;
    uint256 constant SECONDS_IN_HOUR = 3600;
    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant SECONDS_IN_YEAR = 31536000;
    uint256 constant SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR = 126230400;
    uint256 constant SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999 = 883612800;
    uint256 constant SECONDS_IN_100_YEARS = 3155673600;
    uint256 constant SECONDS_IN_400_YEARS = 12622780800;

    // convert yyyy-mm-ddThh:mm:ss.ssZ to uinx timestamp in nano second
    function convertDateTimeStringToTimestamp(string memory _dt) internal pure returns (uint256) {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint32 decimal;

        (year, month, day, hour, minute, second, decimal) = convertDateTimeStringToYMDHMS(_dt);
        return convertYMDHMStoTimestamp(year, month, day, hour, minute, second, decimal);
    }

    function convertDateTimeStringToYMDHMS(string memory _dt)
        internal
        pure
        returns (uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second, uint32 decimal)
    {
        strings.slice memory sISOdateTime = _dt.toSlice();
        strings.slice memory sISOdate;
        strings.slice memory sISOtime;

        sISOdate = sISOdateTime.split("T".toSlice());
        sISOtime = sISOdateTime;

        (year, month, day) = convertDateStringToYMD(sISOdate.toString());
        (hour, minute, second, decimal) = splitTimeInt(sISOtime.toString());
    }

    function convertDateStringToYMD(string memory _dt) internal pure returns (uint16 year, uint8 month, uint8 day) {
        strings.slice[3] memory sArr = splitISOslice(_dt);
        strings.slice memory sYear = sArr[0];
        strings.slice memory sMonth = sArr[1];
        strings.slice memory sDay = sArr[2];

        year = convertSliceToUint16(sYear);
        month = convertSliceToUint8(sMonth);
        day = convertSliceToUint8(sDay);
    }

    function splitTimeInt(string memory _time)
        internal
        pure
        returns (uint8 hour, uint8 minute, uint8 second, uint32 decimal)
    {
        strings.slice[4] memory sArr = splitTimeSlice(_time);
        strings.slice memory sHour = sArr[0];
        strings.slice memory sMinute = sArr[1];
        strings.slice memory sSecond = sArr[2];
        strings.slice memory sDecimal = sArr[3];

        bytes memory decimalString = bytes(sDecimal.toString());
        bytes memory paddedStr = new bytes(9);
        uint256 i;
        for (i = 0; i < bytes(decimalString).length; i++) {
            paddedStr[i] = decimalString[i];
        }

        while (i < 9) {
            paddedStr[i] = "0";
            i++;
        }

        bytes32 paddedBytes = StringUtils.stringToBytes32(string(paddedStr));

        hour = convertSliceToUint8(sHour);
        minute = convertSliceToUint8(sMinute);
        second = convertSliceToUint8(sSecond);
        decimal = uint32(StringUtils.bytesToUInt(paddedBytes));
    }

    function splitISOslice(string memory _dt) private pure returns (strings.slice[3] memory) {
        strings.slice[3] memory sArr;

        strings.slice memory sDate = _dt.toSlice();
        strings.slice memory sHyphen = "-".toSlice();

        sArr[0] = sDate.split(sHyphen);
        sArr[1] = sDate.split(sHyphen);
        sArr[2] = sDate;

        return sArr;
    }

    function convertSliceToUint32(strings.slice memory s) private pure returns (uint32) {
        bytes32 digits;
        digits = StringUtils.stringToBytes32(s.toString());

        return uint32(StringUtils.bytesToUInt(digits));
    }

    function convertSliceToUint16(strings.slice memory s) private pure returns (uint16) {
        bytes32 digits;
        digits = StringUtils.stringToBytes32(s.toString());

        return uint16(StringUtils.bytesToUInt(digits));
    }

    function convertSliceToUint8(strings.slice memory s) private pure returns (uint8) {
        bytes32 digits;
        digits = StringUtils.stringToBytes32(s.toString());

        return uint8(StringUtils.bytesToUInt(digits));
    }

    // hh:mm:ss.ssZ into hh, mm, ss, decimals
    function splitTimeSlice(string memory _time) private pure returns (strings.slice[4] memory) {
        strings.slice[4] memory sArr;

        strings.slice memory sTime = _time.toSlice();
        strings.slice memory sColon = ":".toSlice();
        strings.slice memory sDot = ".".toSlice();
        strings.slice memory sZ = "Z".toSlice();

        sArr[0] = sTime.split(sColon);
        sArr[1] = sTime.split(sColon);
        sArr[2] = sTime.split(sDot);
        sArr[3] = sTime.split(sZ);

        return sArr;
    }

    function addYearSeconds(uint256 _ts, uint16 _year) private pure returns (uint256) {
        uint16 yearCounter;
        uint256 ts = _ts;

        if (_year < 1972) {
            ts += (_year - 1970) * SECONDS_IN_YEAR;
        } else {
            ts += 2 * SECONDS_IN_YEAR;
            yearCounter = 1972;

            if (_year >= 2000) {
                ts += SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999;
                yearCounter = 2000;

                (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 400, SECONDS_IN_400_YEARS);
                (yearCounter, ts) = incrementLeapYear(_year, yearCounter, ts);
                (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 100, SECONDS_IN_100_YEARS);
            }

            (yearCounter, ts) =
                incrementYearAndTimestamp(_year, yearCounter, ts, 4, SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR);
            (yearCounter, ts) = incrementLeapYear(_year, yearCounter, ts);
            (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 1, SECONDS_IN_YEAR);
        }

        return ts;
    }

    function addMonthSeconds(uint16 _year, uint8 _month) private pure returns (uint256) {
        uint32[13] memory monthSecondsMap;

        if (isLeapYear(_year)) {
            monthSecondsMap = [
                0,
                2678400,
                5184000,
                7862400,
                10454400,
                13132800,
                15724800,
                18403200,
                21081600,
                23673600,
                26352000,
                28944000,
                31622400
            ];
        } else {
            monthSecondsMap = [
                0,
                2678400,
                5097600,
                7776000,
                10368000,
                13046400,
                15638400,
                18316800,
                20995200,
                23587200,
                26265600,
                28857600,
                31536000
            ];
        }

        return uint256(monthSecondsMap[_month - 1]);
    }

    function incrementYearAndTimestamp(
        uint16 _year,
        uint16 _yearCounter,
        uint256 _ts,
        uint16 _divisor,
        uint256 _seconds
    ) private pure returns (uint16 year, uint256 ts) {
        uint256 res;

        res = uint256((_year - _yearCounter) / _divisor);
        year = uint16(_yearCounter + (res * _divisor));
        ts = _ts + (res * _seconds);
    }

    function incrementLeapYear(uint16 _year, uint16 _yearCounter, uint256 _ts)
        private
        pure
        returns (uint16 yearCounter, uint256 ts)
    {
        yearCounter = _yearCounter;
        ts = _ts;

        if ((yearCounter < _year) && isLeapYear(yearCounter)) {
            yearCounter += 1;
            ts += SECONDS_IN_YEAR + SECONDS_IN_DAY;
        }
    }

    function isLeapYear(uint16 _year) internal pure returns (bool) {
        if ((_year % 4) != 0) return false;
        if (((_year % 400) == 0) || ((_year % 100) != 0)) return true;

        return false;
    }

    function convertYMDHMStoTimestamp(
        uint16 _year,
        uint8 _month,
        uint8 _day,
        uint8 _hour,
        uint8 _minute,
        uint8 _second,
        uint32 _decimals
    ) internal pure returns (uint256) {
        uint256 ts = 0;

        ts = addYearSeconds(ts, _year);
        ts += addMonthSeconds(_year, _month);
        ts += (_day - 1) * SECONDS_IN_DAY;
        ts += _hour * SECONDS_IN_HOUR;
        ts += _minute * SECONDS_IN_MINUTE;
        ts += uint256(_second);

        return ts * 1_000_000_000 + _decimals;
    }
}
