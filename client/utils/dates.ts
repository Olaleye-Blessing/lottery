export const humanReadAbleDate = ({
	date,
	locales,
	options,
}: {
	date: string | Date | number;
	locales?: Intl.LocalesArgument;
	options?: Intl.DateTimeFormatOptions;
}) => {
	if (typeof date === 'string' || typeof date === 'number')
		date = new Date(date);

	return new Date(date).toLocaleDateString(locales, options);
};
